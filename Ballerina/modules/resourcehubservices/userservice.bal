import ballerina/http;
import ballerina/io;
import ballerina/random;
import ballerina/sql;
import ballerina/email;

public type User record {|
    int id?;
    string username;
    string profile_picture_url;
    string usertype;
    string email;
    string phone_number;
    string password?;
    string additional_details;
    string created_at;
|};

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173", "*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type"]
    }
}

service /user on ln {
    resource function get details() returns User[]|error {
        stream<User, sql:Error?> resultStream =
            dbClient->query(`SELECT * FROM users`);

        User[] users = [];
        check resultStream.forEach(function(User user) {
            users.push(user);
        });

        return users;
    }

    resource function post add(@http:Payload User user) returns json|error {
        float randomValue = random:createDecimal() * 99;
        string randomString = randomValue.toString();
        sql:ExecutionResult result = check dbClient->execute(
            `insert into 
            users (username,profile_picture_url,usertype,email,phone_number,password,additional_details,created_at)
            values (${user.username},${user.profile_picture_url},${user.usertype},${user.email},${user.phone_number},${randomString},${user.additional_details},${user.created_at})`
        );
        if result.affectedRowCount != 0 {

            email:Message email = {
                to: [user.email],

                subject: "Login Password",
                body: "this is your password "+ randomString + " \n" +
                      "Please change your password after login \n" +
                      "http://localhost:5173/login"
            };

            check emailClient->sendMessage(email);

            return {
                message: "User not added successfully"
            };
        }
    }

    resource function delete  details/[int id]() returns json|error {
        sql:ExecutionResult result = check dbClient->execute(`
            DELETE FROM users WHERE id = ${id}
        `);

        if result.affectedRowCount == 0 {
            return {
                message: "User not found"
            };
        }

        return {
            message: "User deleted successfully"
        };
        
    }

}

public function UserManagementService() returns error? {
    io:println("UserManagement service started on port 9090");
}

