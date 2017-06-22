//
//  main.swift
//  kcutil
//

import Foundation

let args = CommandLine.arguments
let argCount = CommandLine.arguments.count
var errorFlag = false
let keychain = KeychainHelper()

// CONVERT ALL THIS PARAMETER STUFF TO LINUX-STYLE GETOPT_LONGARGC / ARGV LATER...

if(argCount>1) {
    // Switch and run based on main argument value
    switch(args[1]) {
        case "-get":
            if(argCount==3) {
                do {
                    try print(keychain.findKey(service: args[2]))
                }
                catch (_){
                    print("No entry found for \(args[2])")
                }
            }
            else {
                print("Incorrect amount of arguments for -get. Should be -get <name>" )
        }
        
        case "-create":
            if(argCount==3) {
                do {
                    let pwd = getpass("Enter the value to be stored in Keychain: ")
                    let valueToBeStored = String.init(cString: pwd!)
                    try keychain.createKey(service: args[2], username: "kcutil", password: valueToBeStored)
                }
                catch (_){
                    print("Error creating keychain value. Already exists?")
                }
            }
            else {
                print("Incorrect amount of arguments for -create. Should be -create <name>" )
            }
            
        case "-replace":
            if(argCount==3) {
                do {
                    let pwd = getpass("Enter the value to be stored in Keychain: ")
                    let valueToBeStored = String.init(cString: pwd!)
                    try keychain.recreateRecord(service: args[2], username: "kcutil", password: valueToBeStored)
                }
                catch (_){
                    print("Error replacing keychain value")
                }
            }
            else {
                print("Incorrect amount of arguments for -replace. Should be -replace <name>" )
        }
        
        case "-delete":
            if(argCount==3) {
                do {
                    try keychain.deleteKey(service: args[2], username: "kcutil")
                }
                catch (_){
                    print("No entry found for \(args[2])")
                }
            }
            else {
                print("Incorrect amount of arguments for -delete. Should be -delete <name>" )
        }

        case "-list":
            if(argCount==2) {
                let results = keychain.listUsersKeychains()
                for str in results {
                    print(str)
                }
            }
            else {
                print("Incorrect amount of arguments for -list. Should be -list" )
            }

        case "-bfg":
            if(argCount==2) {
                keychain.deleteLoginKeychain()
                print("Login keychain destroyed" )
            }
            else {
                print("Incorrect amount of arguments for -bfg. Should be -bfg" )
            }

        case "-bfg_reset":
            if(argCount==2) {
                let status = keychain.resetLoginKeychain()
                
                if(status==true) {
                    print("Login keychain destroyed and a new one has been created and set as default Keychain" )
                }
                else {
                    print("Could't find existing Login Keychain" )
                }
            }
            else {
                print("Incorrect amount of arguments for -bfg_reset. Should be -bfg_reset" )
            }
        
        case "-show":
            if(argCount==2) {
                var results: [String]?
                do {
                    let results = try keychain.findKeychainEntries(account: "kcutil")
                    for str in results {
                        print(str)
                    }
                }
                catch (_){
                    print("No entries found")
                }
            }
            else {
                print("Incorrect amount of arguments for -show. Should be -show" )
        }
        
        default:
            errorFlag = true
    }
}
else {
    errorFlag = true
}

if(errorFlag) {
    print("kcutil: Command line utility for managing Keychain keys\n");
    print("         Usage:");
    print("         kcutil -get <name>                  Get value for name from Keychain");
    print("         kcutil -create <name>               Set name and value to Keychain");
    print("         kcutil -replace <name>              Replace value for specific name in Keychain");
    print("         kcutil -delete <name>               Delete value for specific name in Keychain");
    print("         kcutil -list                        Show all user's Keychains");
    print("         kcutil -show                        Show all items stored in Keychain by kcutil");
    print("         kcutil -bfg                         Destroys Login Keychain");
    print("         kcutil -bfg_reset                   Destroys Login Keychain and recreates a new one with empty password and sets it as default Keychain");
    exit(EXIT_FAILURE)
}
