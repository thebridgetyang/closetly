-- File to set up user privileges 

-- Clean up old tables, functions, and procedures
DROP TABLE IF EXISTS permissions;
DROP PROCEDURE IF EXISTS user_add_permission;

-- Retains all the information about what type of user each app user is
-- e.g. emilypan is an Admin, etc. 
CREATE TABLE permissions (
    username         VARCHAR(80),
    role             VARCHAR(30),

    PRIMARY KEY(username)
);

-- Procedure that adds a user's permission level to permissions. When a user
-- adds their role (e.g. stylist, storeowner, personal), this information 
-- must be logged in permissions.
DELIMITER !
CREATE PROCEDURE user_add_permission(username VARCHAR(80), role VARCHAR(30))
BEGIN 
    INSERT INTO permissions(username, role) VALUES (username, role);
END !
DELIMITER ;

-- clean up entries without usernames attached 
DELETE FROM user 
WHERE ISNULL(username);

-- add permissions for current imported users
-- all future users' permissions will be added upon account creation
CALL user_add_permission('emilypan', 'appadmin');
CALL user_add_permission('bridgetyang', 'appadmin');
CALL user_add_permission('ektapatel', 'personal');
