#!/usr/bin/env swift
import Foundation

// TDLib C API bindings
@_silgen_name("td_create_client_id")
func td_create_client_id() -> Int32

@_silgen_name("td_send")
func td_send(_ client_id: Int32, _ request: UnsafePointer<CChar>?)

@_silgen_name("td_receive")
func td_receive(_ timeout: Double) -> UnsafeMutablePointer<CChar>?

@_silgen_name("td_execute")
func td_execute(_ request: UnsafePointer<CChar>?) -> UnsafeMutablePointer<CChar>?

// Helper functions
func dictToJSON(_ dict: [String: Any]) -> String {
    let data = try! JSONSerialization.data(withJSONObject: dict)
    return String(data: data, encoding: .utf8)!
}

func jsonToDict(_ json: String) -> [String: Any]? {
    guard let data = json.data(using: .utf8) else { return nil }
    return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
}

print("Testing connection to Teamgram server...")
print("Server: 127.0.0.1:10443")
print("RSA Fingerprint: 12240908862933197005")
print("")

// Create client
let clientId = td_create_client_id()
print("Created TDLib client with ID: \(clientId)")

// Set TDLib parameters for test server
let params: [String: Any] = [
    "@type": "setTdlibParameters",
    "api_id": 287311,
    "api_hash": "5e6d7b36f0e363cf0c07baf2deb26076",
    "application_version": "1.0",
    "database_directory": "/tmp/tdlib_test",
    "device_model": "MacOS",
    "system_language_code": "en",
    "system_version": "Test",
    "use_test_dc": true  // This is the key - tells TDLib to use test DC
]

print("Sending setTdlibParameters request...")
let paramsJSON = dictToJSON(params)
td_send(clientId, paramsJSON)

// Receive responses
print("\nWaiting for responses from TDLib...")
var receivedCount = 0
let maxReceives = 20

while receivedCount < maxReceives {
    if let response = td_receive(5.0) {
        let responseStr = String(cString: response)
        if let responseDict = jsonToDict(responseStr) {
            let type = responseDict["@type"] as? String ?? "unknown"
            print("[\(receivedCount + 1)] Received: \(type)")

            // Print full response for important events
            if type == "error" || type == "updateAuthorizationState" {
                print("   Details: \(responseDict)")
            }

            // If we get updateAuthorizationState with authorizationStateWaitPhoneNumber, connection works!
            if type == "updateAuthorizationState" {
                if let authState = responseDict["authorization_state"] as? [String: Any],
                   let authType = authState["@type"] as? String {
                    print("   Authorization state: \(authType)")
                    if authType == "authorizationStateWaitPhoneNumber" {
                        print("\nSUCCESS! Connected to Teamgram server!")
                        print("   Server is ready to accept phone number for authentication.")
                        exit(0)
                    }
                }
            }
        }
        receivedCount += 1
    } else {
        print("No more responses (timeout)")
        break
    }
}

print("\nWARNING: Did not reach phone number prompt. Check responses above for errors.")
exit(1)
