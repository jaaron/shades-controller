(** types used by the Alexa Home Automation API,
 *  the Lambda function handling the skill backend
 *  just shunts these to this server.
*)
type supported_property = {
  name : string;
} [@@deriving yojson];;

type endpoint_property = {
  supported : supported_property list;
} [@@deriving yojson];;

type endpoint_capability = {
  typ : string [@key "type"];
  interface: string;
  version: string;
  properties : endpoint_property option;
} [@@deriving yojson];;

type endpoint = {
  endpointId : string;
  friendlyName : string;
  description: string;
  manufacturerName: string;
  displayCategories: string list;
  capabilities : endpoint_capability list;
} [@@deriving yojson];;

type endpoint_list = endpoint list [@@deriving yojson];;
