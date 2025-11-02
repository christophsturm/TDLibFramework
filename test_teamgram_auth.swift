#!/usr/bin/env swift
import Foundation

// TDLib C API bindings
@_silgen_name("td_create_client_id")
func td_create_client_id() -> Int32

@_silgen_name("td_send")
func td_send(_ client_id: Int32, _ request: UnsafePointer<CChar>?)

@_silgen_name("td_receive")
func td_receive(_ timeout: Double) -> UnsafeMutablePointer<CChar>?

// Helper functions
func dictToJSON(_ dict: [String: Any]) -> String {
    let data = try! JSONSerialization.data(withJSONObject: dict)
    return String(data: data, encoding: .utf8)!
}

func jsonToDict(_ json: String) -> [String: Any]? {
    guard let data = json.data(using: .utf8) else { return nil }
    return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
}

print("=== Teamgram Connection Test ===")
print("Server: 127.0.0.1:10443")
print("Test phone: +12025550123")
print("Test code: 12345")
print("")

// Create client
let clientId = td_create_client_id()
print("Created TDLib client ID: \(clientId)\n")

// Set TDLib parameters for test server
let params: [String: Any] = [
    "@type": "setTdlibParameters",
    "api_id": 287311,
    "api_hash": "5e6d7b36f0e363cf0c07baf2deb26076",
    "application_version": "1.0",
    "database_directory": "/tmp/tdlib_teamgram_test",
    "device_model": "MacOS",
    "system_language_code": "en",
    "system_version": "Test",
    "use_test_dc": true  // Connect to teamgram at 127.0.0.1:10443
]

td_send(clientId, dictToJSON(params))

var authenticated = false
var failed = false
let startTime = Date()
let timeout: TimeInterval = 20.0

// Process responses until success, failure, or timeout
while !authenticated && !failed {
    if Date().timeIntervalSince(startTime) > timeout {
        print("Timeout after \(timeout) seconds")
        break
    }

    guard let response = td_receive(1.0) else {
        continue
    }

    let responseStr = String(cString: response)
    guard let responseDict = jsonToDict(responseStr) else {
        continue
    }

    let type = responseDict["@type"] as? String ?? "unknown"

    if type == "updateAuthorizationState" {
        if let authState = responseDict["authorization_state"] as? [String: Any],
           let authType = authState["@type"] as? String {

            print("Authorization state: \(authType)")

            if authType == "authorizationStateWaitPhoneNumber" {
                print("Connected to server! Sending test phone number...\n")

                let phoneRequest: [String: Any] = [
                    "@type": "setAuthenticationPhoneNumber",
                    "phone_number": "+12025550123"
                ]
                td_send(clientId, dictToJSON(phoneRequest))
            }
            else if authType == "authorizationStateWaitCode" {
                print("Phone number accepted! Sending verification code...\n")

                let codeRequest: [String: Any] = [
                    "@type": "checkAuthenticationCode",
                    "code": "12345"
                ]
                td_send(clientId, dictToJSON(codeRequest))
            }
            else if authType == "authorizationStateReady" {
                print("SUCCESS! Authenticated with teamgram server!")
                print("   Full authentication flow completed\n")
                authenticated = true
            }
            else if authType == "authorizationStateWaitRegistration" {
                print("New user! Registering...\n")

                let registerRequest: [String: Any] = [
                    "@type": "registerUser",
                    "first_name": "Test",
                    "last_name": "User"
                ]
                td_send(clientId, dictToJSON(registerRequest))
            }
        }
    }
    else if type == "error" {
        let code = responseDict["code"] as? Int ?? 0
        let message = responseDict["message"] as? String ?? "Unknown error"
        print("ERROR \(code): \(message)\n")
        if code != 0 {
            failed = true
        }
    }
}

if authenticated {
    exit(0)
} else {
    print("\nWARNING: Authentication not completed")
    exit(1)
}
