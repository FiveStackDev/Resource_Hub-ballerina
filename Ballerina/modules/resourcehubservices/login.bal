import ballerina/http;
import ballerina/jwt;
import ballerina/io;
import ballerina/sql;

// JWT issuer configuration
jwt:IssuerConfig jwtIssuerConfig = {
    username: "ballerina",
    issuer: "ballerina",
    audience: ["ballerina.io"],
    signatureConfig: {
        config: {
            keyFile: "certificate.key"
        }
    },
    expTime: 3600 
};

// JWT validator configuration
jwt:ValidatorConfig jwtValidatorConfig = {
    issuer: "ballerina",
    audience: ["ballerina.io"],
    signatureConfig: {
        certFile: "certificate.crt"
    },
    clockSkew: 60
};


@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173", "*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type"]
    }
}
service /auth on ln {

    resource function post login(@http:Payload record {string email; string password;} credentials) returns json|error {
        
        sql:ParameterizedQuery query = `SELECT username,id, email, password, usertype FROM users WHERE email = ${credentials.email}`;
        record {|string username;int id;string email; string password; string usertype;|}|sql:Error result = dbClient->queryRow(query);

        if (result is sql:Error) {
            if (result is sql:NoRowsError) {
                io:println("Invalid email: " + credentials.email);
                return error("Invalid email");
            } else {
                io:println("Database error: " + result.message());
                return error("Database error");
            }
        }

        if (result.password == credentials.password) {
            jwt:IssuerConfig config = jwtIssuerConfig;
            config.username = credentials.email;
            config.customClaims = {"role": result.usertype};
            config.customClaims = {"username": result.username};
            config.customClaims = {"id": result.id};
            string token = check jwt:issue(config);

            return {token: token, usertype: result.usertype , username: result.username,id: result.id, email: result.email};
        } else {
            io:println("Invalid password for user: " + credentials.email);
            return error("Invalid password");
        }
    }

    resource function get protected(http:Request req) returns string|error {
        io:println("Accessing protected resource");
        
        string|error authHeader = req.getHeader("Authorization");
        if (authHeader is error) {
            io:println("Authorization header not found");
            return error("Authorization header not found");
        }

        string token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;
        
        jwt:Payload|error payload = check jwt:validate(token, jwtValidatorConfig);
        if (payload is jwt:Payload) {
            io:println("Protected data accessed successfully");
            return "Protected data accessed successfully";
        } else {
            io:println("Unauthorized access attempt");
            return error("Unauthorized");
        }
    }
}
