# kcutil

macOS command line tool to demonstrate Keychain APIs using Swift.

         Usage:
         kcutil -get <name>                  Get value for name from Keychain
         kcutil -create <name>               Set name and value to Keychain
         kcutil -replace <name>              Replace value for specific name in Keychain
         kcutil -delete <name>               Delete value for specific name in Keychain
         kcutil -list                        Show all user's Keychains
         kcutil -show                        Show all items stored in Keychain by kcutil
         kcutil -bfg                         Destroys Login Keychain
         kcutil -bfg_reset                   Destroys Login Keychain and recreates a new one with empty password and sets it as default Keychain
