'use strict';

var https = require('https');

function backend_req(method, path, token, callback) {
    log('DEBUG', `${method}: https://${process.env.BACKEND_HOST}:${process.env.BACKEND_PORT}/${path}`);
    let req = https.request({
            hostname: process.env.BACKEND_HOST,
            port: process.env.BACKEND_PORT,
            method: method,
            path: path,
            requestCert: true,
            headers: { 'AuthToken': token }
        },
        (res) => {
            log('DEBUG', 'Reading chunks');
            let rawData = '';
            res.on('data', (chunk) => { rawData += chunk; });
            res.on('end', () => {
                log('DEBUG', `Done: ${rawData}`);
                callback(JSON.parse(rawData));
            });
        }
    );
    req.on('error', (e) => {
        log('ERROR', `HTTPS Request error: ${e}`);
        callback({"error": e});
    });
    req.end();
}

function get_from_backend(path, token, callback) {
    backend_req('GET', path, token, callback);
}

function put_to_backend(path, token, callback){
    backend_req('PUT', path, token, callback);
}

function log(title, msg) {
    console.log(`[${title}] ${msg}`);
}

function generateMessageID() {
    var uuid = "",
        i, random;
    for (i = 0; i < 32; i++) {
        random = Math.random() * 16 | 0;

        if (i == 8 || i == 12 || i == 16 || i == 20) {
            uuid += "-";
        }
        uuid += (i == 12 ? 4 : (i == 16 ? (random & 3 | 8) : random)).toString(16);
    }
    return uuid;
}

function generateError(request, typ, msg) {
    return {
        event: {
            header: {
                namespace: "Alexa",
                name: "ErrorResponse",
                messageId: generateMessageID(),
                correlationToken: request.header.correlationToken,
                payloadVersion: "3"
            },
            endpoint: {
                endpointId: request.endpoint.endpointId
            },
            payload: {
                type: typ,
                message: msg
            }
        }
    }
}

/**
 * Generate a response message
 *
 * @param {string} name - Directive name
 * @param {Object} payload - Any special payload required for the response
 * @returns {Object} Response object
 */
function generateResponse(request, response) {
    if (response.error) {
        return generateError(request, 'INTERNAL_ERROR', "I don't know what went wrong.")
    }
    return {
        context: {
            properties: [{
                namespace: "Alexa.BrightnessController",
                name: "brightness",
                value: response.brightness,
            }]
        },
        event: {
            header: {
                namespace: "Alexa",
                name: "Response",
                messageId: generateMessageID(),
                correlationToken: request.header.correlationToken,
                payloadVersion: '3',
            },
            endpoint: {
                scope: request.endpoint.scope,
                endpointId: request.endpoint.endpointId
            },
            payload: {}
        }
    };
}

function getDevicesFromPartnerCloud(token, callback) {
    get_from_backend('/shades', token, callback);
}

function validateToken(token, callback) {
    https.get(`https://api.amazon.com/user/profile?access_token=${token}`,
        (res) => {
            const statusCode = res.statusCode;
            if (statusCode != 200) {
                callback(false);
            }
            res.setEncoding('utf8');
            let rawData = '';
            res.on('data', (chunk) => { rawData += chunk; });
            res.on('end', () => {
                try {
                    const response = JSON.parse(rawData);
                    if (response.error) {
                        callback(false);
                    }
                    else if (response.email != process.env.USER_EMAIL) {
                        callback(false);
                    }
                    else {
                        callback(true);
                    }
                }
                catch (e) {
                    log('ERROR', e.message);
                    callback(false);
                }
            });
        }
    );
}

function isDeviceOnline(applianceId) {
    log('DEBUG', `isDeviceOnline (applianceId: ${applianceId})`);

    /**
     * Always returns true for sample code.
     * You should update this method to your own validation.
     */
    return true;
}

/**
 * Main logic
 */

/**
 * This function is invoked when we receive a "Discovery" message from Alexa Smart Home Skill.
 * We are expected to respond back with a list of appliances that we have discovered for a given customer.
 *
 * @param {Object} request - The full request object from the Alexa smart home service. This represents a DiscoverAppliancesRequest.
 *     https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/smart-home-skill-api-reference#discoverappliancesrequest
 *
 * @param {function} callback - The callback object on which to succeed or fail the response.
 *     https://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-handler.html#nodejs-prog-model-handler-callback
 *     If successful, return <DiscoverAppliancesResponse>.
 *     https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/smart-home-skill-api-reference#discoverappliancesresponse
 */
function handleDiscovery(request, callback) {
    log('DEBUG', `Discovery Request: ${JSON.stringify(request)}`);

    /**
     * Get the OAuth token from the request.
     */
    const userAccessToken = request.payload.scope.token.trim();

    /**
     * Generic stub for validating the token against your cloud service.
     * Replace isValidToken() function with your own validation.
     */
    validateToken(userAccessToken, function(validToken) {
        if (!validToken) {
            const errorMessage = `Discovery Request [${request.header.messageId}] failed. Invalid access token: ${userAccessToken}`;
            log('ERROR', errorMessage);
            callback(new Error(errorMessage));
        }
        /**
         * Assume access token is valid at this point.
         * Retrieve list of devices from cloud based on token.
         *
         * For more information on a discovery response see
         *  https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/smart-home-skill-api-reference#discoverappliancesresponse
         */
        getDevicesFromPartnerCloud(userAccessToken, (res) => {
            if (res.error) {
                callback(new Error("Error fetching data from backend"));
            }
            const response = {
                event: {
                    header: {
                        messageId: generateMessageID(),
                        name: 'Discover.Response',
                        namespace: 'Alexa.Discovery',
                        payloadVersion: '3',
                    },
                    payload: {
                        endpoints: res,
                    }
                }
            };

            /**
             * Log the response. These messages will be stored in CloudWatch.
             */
            log('DEBUG', `Discovery Response: ${JSON.stringify(response)}`);

            /**
             * Return result with successful message.
             */
            callback(null, response);
        })
    });
}

/**
 * A function to handle control events.
 * This is called when Alexa requests an action such as turning off an appliance.
 *
 * @param {Object} request - The full request object from the Alexa smart home service.
 * @param {function} callback - The callback object on which to succeed or fail the response.
 */
function handleControl(request, callback) {
    /**
     * Get the access token.
     */
    const userAccessToken = request.endpoint.scope.token.trim();

    /**
     * Generic stub for validating the token against your cloud service.
     * Replace isValidToken() function with your own validation.
     *
     * If the token is invliad, return InvalidAccessTokenError
     *  https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/smart-home-skill-api-reference#invalidaccesstokenerror
     */
    validateToken(userAccessToken, (isValid) => {
        if (!isValid) {
            log('ERROR', `Discovery Request [${request.header.messageId}] failed. Invalid access token: ${userAccessToken}`);
            callback(null, generateResponse('InvalidAccessTokenError', {}));
            return;
        }

        /**
         * Grab the applianceId from the request.
         */
        const applianceId = request.endpoint.endpointId

        /**
         * If the applianceId is missing, return UnexpectedInformationReceivedError
         *  https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/smart-home-skill-api-reference#unexpectedinformationreceivederror
         */
        if (!applianceId) {
            callback(null, generateError('INVALID_DIRECTIVE', 'No endpoint specified in message'));
            return;
        }

        /**
         * At this point the applianceId and accessToken are present in the request.
         *
         * Please review the full list of errors in the link below for different states that can be reported.
         * If these apply to your device/cloud infrastructure, please add the checks and respond with
         * accurate error messages. This will give the user the best experience and help diagnose issues with
         * their devices, accounts, and environment
         *  https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/smart-home-skill-api-reference#error-messages
         */
        /*
        if (!isDeviceOnline(applianceId, userAccessToken)) {
            log('ERROR', `Device offline: ${applianceId}`);
            callback(null, generateResponse('TargetOfflineError', {}));
            return;
        }
        */

        switch (request.header.name) {
            case 'SetBrightness':
                {
                    const percentage = request.payload.brightness;
                    log('DEBUG', `Setting brightness to ${percentage}`);

                    if (!percentage) {
                        callback(null, generateError('INVALID_DIRECTIVE', 'No brightness value provided'));
                        return;
                    }

                    put_to_backend(`/shade/${applianceId}/${percentage}`, userAccessToken, (res) => {
                        callback(null, generateResponse(request, res));
                    });
                    return;
                }

            case 'AdjustBrightness':
                {
                    const delta = request.payload.brightnessDelta;
                    if (!delta) {
                        callback(null, generateResponse('INVALID_DIRECTIVE', 'No brightness delta provided'));
                        return;
                    }
                    put_to_backend(`/shade/${applianceId}/${delta}/delta`, userAccessToken, (res) => {
                        callback(null, generateResponse(request, res));
                    });
                    return;
                }

            default:
                {
                    log('ERROR', `No supported directive name: ${request.header.name}`);
                    callback(null, generateError('INVALID_DIRECTIVE', `Unknown command ${request.header.name}`));
                    return;
                }
        }
    });
    return;
}

/**
 * Main entry point.
 * Incoming events from Alexa service through Smart Home API are all handled by this function.
 *
 * It is recommended to validate the request and response with Alexa Smart Home Skill API Validation package.
 *  https://github.com/alexa/alexa-smarthome-validation
 */
exports.handler = (request, context, callback) => {
    switch (request.directive.header.namespace) {
        /**
         * The namespace of 'Alexa.ConnectedHome.Discovery' indicates a request is being made to the Lambda for
         * discovering all appliances associated with the customer's appliance cloud account.
         *
         * For more information on device discovery, please see
         *  https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/smart-home-skill-api-reference#discovery-messages
         */
        case 'Alexa.Discovery':
            handleDiscovery(request.directive, callback);
            break;

            /**
             * The namespace of "Alexa.ConnectedHome.Control" indicates a request is being made to control devices such as
             * a dimmable or non-dimmable bulb. The full list of Control events sent to your lambda are described below.
             *  https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/smart-home-skill-api-reference#payload
             */
        case 'Alexa.BrightnessController':
        case 'Alexa.PercentageController':
            handleControl(request.directive, callback);
            break;

            /**
             * The namespace of "Alexa.ConnectedHome.Query" indicates a request is being made to query devices about
             * information like temperature or lock state. The full list of Query events sent to your lambda are described below.
             *  https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/smart-home-skill-api-reference#payload
             *
             * TODO: In this sample, query handling is not implemented. Implement it to retrieve temperature or lock state.
             */
            // case 'Alexa.Query':
            //     handleQuery(request, callback);
            //     break;

            /**
             * Received an unexpected message
             */
        default:
            {
                const errorMessage = `
                                    No supported namespace: $ { request.directive.header.namespace }
                                    `;
                log('ERROR', errorMessage);
                callback(new Error(errorMessage));
            }
    }
};
