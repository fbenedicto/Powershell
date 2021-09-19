#Ferran Benedicto 2021 - GPO Security Test

This little script checks a series of checks on the security policy
---------------------
Functions:

Sysvol replication: Check there is a good replication between the different Domain controllers, if in some
domain controller is not replicated, it will appear blank in the "Sysvol" part.

ACL's: Check if you are correctly applying FileSystem permissions on the indicated folder.

Applocker: Checks from the policies that are applying to the computer if a user or group has permissions
of execution on the executable indicated.
----------------------
----------------------
Instructions for use:

For the program to work correctly, you have to copy the folder to the root D: \ of the server to check -> D: \ TestGPO

** IMPORTANT NOTE: The execution path can be modified, but the BATCH will have to be modified

Once copied, you have to run the executable "TESTGPO.BAT"

If you don't want to make any checks, press the "ESC" key, this will jump to the next check.

** NOTE: If an invalid / non-existent value is entered on any of the validations, the program will be closed **
