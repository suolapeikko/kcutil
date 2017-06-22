//
//  KeychainHelper.swift
//  kcutil
//

import Foundation

enum KeychainError : Error {
    case RuntimeError(String)
}

struct AccountItem {
    var username: String = ""
    var password: String = ""
}

struct KeychainHelper {
    
    ///  Helper function to enable easy keychain username and password access
    /// - parameters:
    ///   - String: Service name, eg. app name
    /// - throws: KeychainError
    /// - returns:
    ///   - AccountItem: account information struct
    func loginItems(service:String) throws -> AccountItem {
        
        var account = AccountItem()
        
        account.username = try findKeychainAttribute(service: service, attribute: kSecAttrAccount)
        account.password = try findKey(service: service)
        
        return account
    }
    
    /// Helper function which deletes the old keychain item and creates a new to replace it
    ///
    /// - parameters:
    ///   - String: Service name, eg. app name
    ///   - String: User's name
    ///   - String: Text, eg. password, to be stored int the login keychain
    /// - throws: Decoded error description
    func recreateRecord(service: String, username: String, password: String) throws {
        
        do {
            try deleteKey(service: service, username: username)
        }
        catch(_) {
            // Ignore, as there might not always be keychain item available
        }
        try createKey(service: service, username: username, password: password)
    }
    
    /// Find keychain items based on account name
    /// - parameters:
    ///   - String: Account name, eg. app or user name
    /// - throws: KeychainError
    /// - returns:
    ///   - String: attribute name
    func findKeychainEntries(account: String) throws -> [String] {
        
        let keychainQuery: [NSObject: AnyObject] =  [
            kSecClass : kSecClassGenericPassword,
            kSecAttrAccount : account as AnyObject,
            kSecReturnAttributes : kCFBooleanTrue,
            kSecReturnData : kCFBooleanFalse,
            kSecMatchLimit : kSecMatchLimitAll]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)
        if status == errSecSuccess,
            let retrievedData = dataTypeRef as! NSArray? {
            var results = [String]()
            for value in retrievedData as! [[String:Any]] {
                results.append(value[kSecAttrService as String] as! String)
            }
            if(results.isEmpty) {
                throw KeychainError.RuntimeError(String(describing: "Invalid CFString attribute value"))
            }
            return results
            
        } else {
            throw KeychainError.RuntimeError(String(describing: SecCopyErrorMessageString(status, nil)))
        }
    }
    
    /// Find keychain item attribute based on a service name
    /// - parameters:
    ///   - String: Service name, eg. app name
    ///   - CFString: attribute value, eg. kSecAttrAccount
    /// - throws: KeychainError
    /// - returns:
    ///   - String: attribute name
    func findKeychainAttribute(service: String, attribute: CFString) throws -> String {
        
        let keychainQuery: [NSObject: AnyObject] =  [
            kSecClass : kSecClassGenericPassword,
            kSecAttrService : service as AnyObject,
            kSecReturnAttributes : kCFBooleanTrue,
            kSecReturnData : kCFBooleanTrue,
            kSecMatchLimit : kSecMatchLimitOne]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)
        if status == errSecSuccess,
            let retrievedData = dataTypeRef as! NSDictionary? {
            let attr = retrievedData[attribute] as! String
            if(attr.isEmpty) {
                throw KeychainError.RuntimeError(String(describing: "Invalid CFString attribute value"))
            }
            return attr
            
        } else {
            throw KeychainError.RuntimeError(String(describing: SecCopyErrorMessageString(status, nil)))
        }
    }
    
    /// Update keychain attribute based on a service name
    /// - parameters:
    ///   - String: Service name, eg. app name
    ///   - CFString: attribute value, eg. kSecAttrAccount
    ///   - String: new attribute value to be updated
    /// - throws: KeychainError
    func updateKeychainAttribute(service: String, attribute: CFString, value: String) throws {
        
        let keychainQuery: [NSObject: AnyObject] =  [
            kSecClass : kSecClassGenericPassword,
            kSecAttrService : service as AnyObject,
            kSecReturnAttributes : kCFBooleanTrue,
            kSecReturnData : kCFBooleanTrue,
            kSecMatchLimit : kSecMatchLimitOne]
        
        let updatedValues: [NSObject: AnyObject] =  [
            attribute : value as AnyObject]
        
        let status = SecItemUpdate(keychainQuery as CFDictionary, updatedValues as CFDictionary)
        if(status != errSecSuccess) {
            throw KeychainError.RuntimeError(String(describing: SecCopyErrorMessageString(status, nil)))
        }
    }
    
    /// This function creates an item to user's login keychain
    ///
    /// - parameters:
    ///   - String: Service name, eg. app name
    ///   - String: User's name
    ///   - String: Text, eg. password, to be stored int the login keychain
    /// - throws: Decoded error description
    func createKey(service: String, username: String, password: String) throws {
        
        var resultCode: OSStatus
        
        resultCode = SecKeychainAddGenericPassword(nil, UInt32(service.characters.count), service, UInt32(username.characters.count), username, UInt32(password.characters.count), password, nil)
        
        guard resultCode == 0 else {throw KeychainError.RuntimeError(String(describing: SecCopyErrorMessageString(resultCode, nil)))}
    }
    
    /// This function finds an item from user's login keychain
    ///
    /// - parameters:
    ///   - String: Service name, eg. app name
    /// - throws: The item, eg. password, that has been stored to the login keychain
    /// - returns: Key value as String
    func findKey(service: String) throws -> String  {
        
        var resultCode: OSStatus
        var passwordLength: UInt32 = 0
        var passwordPointer: UnsafeMutableRawPointer? = nil
        var keychainItem: SecKeychainItem?
        let username = ""
        
        resultCode = SecKeychainFindGenericPassword(nil, UInt32(service.characters.count), service, UInt32(username.characters.count), username, &passwordLength, &passwordPointer, &keychainItem)
        
        guard resultCode == 0 else {throw KeychainError.RuntimeError(String(describing: SecCopyErrorMessageString(resultCode, nil)))}
        
        return NSString(bytes: passwordPointer!, length: Int(passwordLength), encoding: String.Encoding.utf8.rawValue) as String!
    }
    
    /// This function deletes an item from user's login keychain
    ///
    /// - parameters:
    ///   - String: Service name, eg. app name
    ///   - String: User's name
    /// - throws: Decoded error description
    func deleteKey(service: String, username: String) throws {
        
        var resultCode: OSStatus
        var passwordLength: UInt32 = 0
        var passwordPointer: UnsafeMutableRawPointer? = nil
        var keychainItem: SecKeychainItem?
        
        resultCode = SecKeychainFindGenericPassword(nil, UInt32(service.characters.count), service, UInt32(username.characters.count), username, &passwordLength, &passwordPointer, &keychainItem)
        
        guard resultCode == 0 else {throw KeychainError.RuntimeError(String(describing: SecCopyErrorMessageString(resultCode, nil)))}
        
        resultCode = SecKeychainItemDelete(keychainItem!)
        
        guard resultCode == 0 else {throw KeychainError.RuntimeError(String(describing: SecCopyErrorMessageString(resultCode, nil)))}
    }
    
    /// This function returns a list of user's keychains
    /// - returns: String array containing path names
    func listUsersKeychains() -> [String] {
        
        var searchList: CFArray? = nil
        var retVal = [String]()
        let status = SecKeychainCopySearchList(&searchList)
        
        if(status==errSecSuccess) {
            if let array = searchList as! [Any]! {
                for object in array {
                    let keychain = object as! SecKeychain
                    var pathName = Array(repeating: 0 as Int8, count: 1024)
                    var pathLength = UInt32(pathName.count)
                    let osStatus = SecKeychainGetPath(keychain, &pathLength, &pathName)
                    if(osStatus==errSecSuccess) {
                        let path = FileManager.default.string(withFileSystemRepresentation: pathName, length: Int(pathLength))
                        retVal.append(path)
                    }
                }
            }
        }
        return retVal
    }
    
    // Deletes user's Login keychain
    func deleteLoginKeychain() {
        
        var searchList: CFArray? = nil
        let status = SecKeychainCopySearchList(&searchList)
        
        if(status==errSecSuccess) {
            if let array = searchList as! [Any]! {
                for object in array {
                    let keychain = object as! SecKeychain
                    var pathName = Array(repeating: 0 as Int8, count: 1024)
                    var pathLength = UInt32(pathName.count)
                    let osStatus = SecKeychainGetPath(keychain, &pathLength, &pathName)
                    if(osStatus==errSecSuccess) {
                        let path = FileManager.default.string(withFileSystemRepresentation: pathName, length: Int(pathLength))
                        if path.lowercased().range(of:"login.keychain") != nil {
                            SecKeychainDelete(keychain)
                        }
                    }
                }
            }
        }
    }
    
    // Resets user's Login keychain
    /// - returns: A Boolean value telling whether login keychain could be recreated
    func resetLoginKeychain() -> Bool {
        
        var searchList: CFArray? = nil
        let status = SecKeychainCopySearchList(&searchList)
        var retVal = false
        
        if(status==errSecSuccess) {
            if let array = searchList as! [Any]! {
                for object in array {
                    let keychain = object as! SecKeychain
                    var pathName = Array(repeating: 0 as Int8, count: 1024)
                    var pathLength = UInt32(pathName.count)
                    let osStatus = SecKeychainGetPath(keychain, &pathLength, &pathName)
                    if(osStatus==errSecSuccess) {
                        let path = FileManager.default.string(withFileSystemRepresentation: pathName, length: Int(pathLength))
                        if path.lowercased().range(of:"login.keychain") != nil {
                            SecKeychainDelete(keychain)
                            var newKeychain: SecKeychain?
                            let createStatus = SecKeychainCreate(pathName, 0, "", false, nil, &newKeychain)
                            print(createStatus)
                            SecKeychainSetDefault(newKeychain)
                            retVal = true
                        }
                    }
                }
            }
        }
        return retVal
    }
}
