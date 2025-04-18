import ballerina/http;
import ballerina/sql;
import ballerina/io;


public type MealEvent record {|
    int id?;
    string meal_time;
    string meal_type;
    string username;
    int user_id;
    string submitted_date;
    string meal_request_date;
|};
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173", "*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type"]
    }
}
service /calander on ln{
    // MealEvents endpoints
    resource function get mealevents/[int userid]() returns MealEvent[]|error {
        stream<MealEvent, sql:Error?> resultStream = 
            dbClient->query(`SELECT mealevents.id, meal_time, meal_type, username,user_id, submitted_date, meal_request_date 
            FROM mealevents
            JOIN users ON mealevents.user_id = users.id
            WHERE mealevents.user_id = ${userid}`);
        
        MealEvent[] events = [];
        check resultStream.forEach(function(MealEvent event) {
            events.push(event);
        });

        return events;
    }

    resource function get mealevents() returns MealEvent[]|error {
        stream<MealEvent, sql:Error?> resultStream = 
            dbClient->query(`SELECT mealevents.id, meal_time, meal_type, username,user_id, submitted_date, meal_request_date 
            FROM mealevents
            JOIN users ON mealevents.user_id = users.id`);
        
        MealEvent[] events = [];
        check resultStream.forEach(function(MealEvent event) {
            events.push(event);
        });

        return events;
    }
    resource function post mealevents/add(@http:Payload MealEvent event) returns json|error {
        sql:ExecutionResult result = check dbClient->execute(`
            INSERT INTO mealevents (meal_time, meal_type, user_id, submitted_date, meal_request_date)
            VALUES (${event.meal_time}, ${event.meal_type}, ${event.user_id}, ${event.submitted_date}, ${event.meal_request_date})
        `);

        int|string? lastInsertId = result.lastInsertId;
        if lastInsertId is int {
            event.id = lastInsertId;
            return { message: "Meal event added successfully", id: lastInsertId };
        }

        return { message: "Failed to add meal event" };
    }

    resource function delete mealevents/[int id]() returns json|error {
        sql:ExecutionResult result = check dbClient->execute(`
            DELETE FROM mealevents WHERE id = ${id}
        `);

        if result.affectedRowCount == 0 {
            return { message: "Meal event not found" };
        }

        return { message: "Meal event deleted successfully" };
    }
}

public function startCalanderService() returns error? {
    io:println("Calander service started on port 9090");
}
