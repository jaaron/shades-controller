open Opium.Std;;
open Core;;

(* Replace this with your amazon.com user account email address. Used
   to authorize connections from the lambda function. *)
let authorized_email = "user@host.com";;

type inet_addr = Unix.Inet_addr.t;;
let inet_addr_to_yojson a = `String (Unix.Inet_addr.to_string a)
let inet_addr_of_yojson = function
  | `String s -> (try Result.return (Unix.Inet_addr.of_string s)
                  with e -> Result.fail (Exn.to_string e))
  | j         -> Result.fail (sprintf "Expected dotted ip address string but got %s"
                                (Yojson.Safe.to_string j))
;;

type shade = {
  id   : string;
  name : string;
  description: string;
  ip   : inet_addr;
  port : int;
  zone : (string [@default "default"]);
  state : int ref [@default ref 100];
  pending : (int option ref) [@default ref (Some 100)];
} [@@deriving yojson];;

type shade_list = shade list
[@@deriving yojson];;

let shades_save_file = "shades.json"
let shades = ref [];;

let save_shades () =
  !shades
  |> List.map ~f:(fun (_, s) -> s)
  |> shade_list_to_yojson
  |> Yojson.Safe.to_string
  |> fun data -> Out_channel.write_all shades_save_file ~data

let load_shades () = In_channel.read_all shades_save_file
		     |> Yojson.Safe.from_string
		     |> shade_list_of_yojson
		     |> Result.map_error ~f:(fun s -> failwith s)
		     |> Result.ok_exn
		     |> List.map ~f:(fun shade -> (shade.id, shade))
		     |> fun l -> shades := l

let validate_token tok =
  let open Lwt in
  let open Cohttp in
  let open Cohttp_lwt_unix in
  let (>>?=) = Lwt_result.bind in
  (Client.get (Uri.of_string (sprintf "https://api.amazon.com/user/profile?access_token=%s" tok))
   >>= fun (resp, body) -> (match resp |> Response.status |> Code.code_of_status with
       | 200 -> Lwt_result.return body
       | _   -> Lwt_result.fail "Failed to validate authentication token")
   >>?= fun body -> Lwt_result.ok (Cohttp_lwt.Body.to_string body)
   >>?= (fun body -> (try Lwt_result.return (Yojson.Safe.from_string body)
                      with e -> Lwt_result.fail (sprintf "Failed to parse JSON body: %s\n" (Exn.to_string e))))
   >>?= fun json -> (match json with
       | `Assoc xs -> Lwt_result.return (List.Assoc.find ~equal:(=) xs "error",
                                         List.Assoc.find ~equal:(=) xs "email")
       | _        -> Lwt_result.fail "JSON response not a dictionary?")
   >>?= function
   | (Some e, _) -> Lwt_result.fail "Authorization failed"
   | (None, Some email) -> (if email = `String authorized_email
                            then Lwt_result.return ()
                            else Lwt_result.fail "Invalid user")
   | (None, None) -> Lwt_result.fail "No email address returned")
  >>= function
  | Result.Ok _ -> return true
  | Result.Error e -> (Lwt_io.fprintf Lwt_io.stderr "Authorization Error: %s\n" e
                       >>= fun _ -> return false)

let endpoint_of_shade s =
  Alexa_home_automation.{
    endpointId = s.id;
    friendlyName = s.name;
    description = s.description;
    manufacturerName = "Pendergrass";
    displayCategories = ["OTHER"];
    capabilities = [
      {
        typ = "AlexaInterface";
        interface = "Alexa";
        version = "3";
        properties = None;
      };
      {
        typ = "AlexaInterface";
        interface = "Alexa.BrightnessController";
        version = "3";
        properties = Some {
	    supported = [{name = "brightness"}]
          }
      }
    ]
  };;

let (>>=) = Lwt.(>>=);;
let (>|=) = Lwt.(>|=);;
let return = Lwt.return;;

(* opium uses ezjson which doesn't have a nice deriver...grrr *)
let rec ezjson_of_yojson =
  let open Ezjsonm in
  function
  | `Null -> unit ()
  | `Bool b -> bool b
  | `String s -> string s
  | `Int i -> int i
  | `Float f -> float f
  | `List l -> list ezjson_of_yojson l
  | `Tuple xs -> list ezjson_of_yojson xs
  | `Assoc xs -> dict (List.map ~f:(fun (k,v) -> (k, ezjson_of_yojson v)) xs)
  | `Intlit s -> string s
  | `Variant (s,Some j) -> `A [`String s; ezjson_of_yojson j]
  | `Variant (s, None)  -> `A [`String s]

let int_of_string_pfx s =
  int_of_string (String.strip ~drop:(fun c -> not (Char.is_digit c)) s)

let send_error ?code:(code = `Internal_server_error) msg =
  Lwt_io.printf "\tError: %s\n" msg
  >|= (fun _ -> (`Json Ezjsonm.(dict ["error", string msg])))
  >>= respond' ~code

let register = post "/register" begin fun req ->
    Lwt_io.printf "Handling registration...\n"
    >>= fun _ -> App.string_of_body_exn req
    >>= fun body -> Lwt_io.printf "\t\"%s\"" (String.escaped body)
    >>= fun _ -> (
      let json = Yojson.Safe.from_string body in
      let new_shade = shade_of_yojson json in
      match new_shade with
      | Error e -> send_error e
      | Ok shade -> (Lwt_io.printf "Adding controller %s\n" shade.id
                     >|= (fun _ -> shades := List.Assoc.add ~equal:(=) (!shades) shade.id shade)
                     >|= save_shades
		     >|= (fun _ -> `Json (Ezjsonm.(dict ["response", string "OK"])))
                     >>= respond'))
  end

let poll = post "/shade/:id/poll" begin fun req ->
    let id = param req "id" in
    let shade = List.Assoc.find ~equal:(=) (!shades) id in
    match shade with
    | Some s -> (App.string_of_body_exn req
                 >|= (fun body -> s.state := (int_of_string body))
                 >>= (fun _  ->
                     (match !(s.pending) with
                      | Some tgt -> (s.pending := None;
                                     respond' (`String (string_of_int tgt)))
	              | None     -> respond' (`String ""))))
    | None -> send_error "No such device"
  end

let enumerate = get "/shades" begin fun req ->
    let open Ezjsonm in
    `Json (list (fun (_, s) -> endpoint_of_shade s |>
                               Alexa_home_automation.endpoint_to_yojson
                               |> ezjson_of_yojson) (!shades))
    |> respond'
  end

let zone_enumerate = get "/zone/:name/shades" begin fun req ->
    let zone = param req "name" in
    let open Ezjsonm in
    `Json (list (fun (_, s) -> endpoint_of_shade s |>
			       Alexa_home_automation.endpoint_to_yojson
			       |> ezjson_of_yojson)
	     (List.filter ~f:(fun (_,s) -> s.zone = zone) (!shades)))
    |> respond'
  end

let set shade_id v =
  let shade = List.Assoc.find ~equal:(=) (!shades) shade_id in
  match shade with
  | Some s -> s.pending := Some v ;
    respond' (`Json (Ezjsonm.(dict ["brightness", int v])))
  | None   -> send_error "No such device"

let get_percentage = get "/shade/:id" begin fun req ->
    let id = param req "id" in
    let shade = List.Assoc.find ~equal:(=) (!shades) id in
    match shade with
    | Some s -> respond' (`Json Ezjsonm.(dict ["brightness", int !(s.state)]))
    | None -> send_error "No such device"
  end

let set_percentage = put "/shade/:id/:value" begin fun req ->
    let id = param req "id" in
    let value = param req "value" |> Int.of_string  in
    set id value
  end

let open_shade = put "/shade/:id/open" begin fun req ->
    set (param req "id") 0
  end

let close_shade = put "/shade/:id/close" begin fun req ->
    set (param req "id") 100
  end

let log = Rock.Middleware.create ~name:"log" ~filter:(fun handler req ->
    Lwt_io.printf "%s: Got request %s %s\n"
      Time.(to_string (now ()))
      (Cohttp.Code.string_of_method (Request.meth req))
      (Uri.to_string (Request.uri req))
    >>= fun _ -> handler req)

let auth = Rock.Middleware.create ~name:"auth" ~filter:(fun handler req ->
    match Cohttp.Header.get (Request.headers req) "AuthToken" with
    | Some tok -> (validate_token tok >>=
                   function true -> handler req
                          | false -> (Lwt_io.printf "\tInvalid token\n"
                                      >>= fun _ -> send_error ~code:`Unauthorized "Unauthorized"))
    | None     -> (Lwt_io.printf "\tNo auth token!\n"
                   >>= fun _ -> send_error ~code:`Unauthorized "Unauthorized"))

let ui = Middleware.static ~local_path:"./static" ~uri_prefix:"/ui"

(* Private HTTP only interface (port 8080).
 * NB: Do not expose this to the internet! *)
let registration = App.empty
                   |> App.port 8080
                   |> middleware log
		   |> enumerate
                   |> register
                   |> poll
		   |> set_percentage
		   |> get_percentage
		   |> middleware ui
                   |> App.start

let control = App.empty
              |> App.ssl ~cert:"cert.pem" ~key:"key.pem"
              |> App.port 8443
              |> middleware log
	      |> register
              |> middleware auth
	      |> enumerate
	      |> set_percentage
	      |> get_percentage
              |> open_shade
              |> close_shade
              |> App.start

let main = Lwt.join [registration; control]
let _ = Lwt.on_termination main save_shades;
  load_shades () ;
  Lwt_main.run main;;
