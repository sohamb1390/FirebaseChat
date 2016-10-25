This is a simple chat application using Firebase.

Though I have used my own Firebase storage repo which all of you can also use but I would definitely recommend to create your personal storage in the Firebase. All I am saying this because it's a Anonymous chat app which is basically using a single database in Firebase. So whoever will be using my codebase will actually be using a single DB!

You can change the storage URL from **Constants.swift** file 
which is currently declared as **gs://locationchat-3d569.appspot.com** 

Please make sure that you have created your own storage url before using this application. 

**Also please change your bundle id to whatever you have used to create the project in Firebase** ### **This is mandatory** ###

### Steps to follow ###
* Sign In/Up to the application. Your email id & password are the keys.
* A map will be displayed after that where you can see all the logged in users and their locations. (Detailing of the map is not completed yet)
* Go to the Chat room and you will be able to chat with multiple persons from various locations. Till now I have only implemented the normal text & image chat.


![alt tag](https://github.com/sohamb1390/FirebaseChat/blob/master/Simulator%20Screen%20Shot%2025-Oct-2016%2C%2010.58.44%20PM.png)
