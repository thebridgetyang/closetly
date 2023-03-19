-- File for Password Management section of Final Project

-- Clean up old tables, functions, and procedures.
DROP FUNCTION IF EXISTS make_salt;
DROP TABLE IF EXISTS user_info;
DROP PROCEDURE IF EXISTS add_to_user;
DROP FUNCTION IF EXISTS authenticate;
DROP PROCEDURE IF EXISTS sp_change_password;
DROP PROCEDURE IF EXISTS sp_add_user;

-- (Provided) This function generates a specified number of characters for using as a
-- salt in passwords.
DELIMITER !
CREATE FUNCTION make_salt(num_chars INT) 
RETURNS VARCHAR(20) NOT DETERMINISTIC
BEGIN
    DECLARE salt VARCHAR(20) DEFAULT '';

    -- Don't want to generate more than 20 characters of salt.
    SET num_chars = LEAST(20, num_chars);

    -- Generate the salt!  Characters used are ASCII code 32 (space)
    -- through 126 ('z').
    WHILE num_chars > 0 DO
        SET salt = CONCAT(salt, CHAR(32 + FLOOR(RAND() * 95)));
        SET num_chars = num_chars - 1;
    END WHILE;

    RETURN salt;
END !
DELIMITER ;

-- Provided (you may modify if you choose)
-- This table holds information for authenticating users based on
-- a password.  Passwords are not stored plaintext so that they
-- cannot be used by people that shouldn't have them.
-- You may extend that table to include an is_admin or role attribute if you 
-- have admin or other roles for users in your application 
-- (e.g. store managers, data managers, etc.)
CREATE TABLE user_info (
    -- Usernames are up to 20 characters.
    username VARCHAR(20) PRIMARY KEY,

    -- Salt will be 8 characters all the time, so we can make this 8.
    salt CHAR(8) NOT NULL,

    -- We use SHA-2 with 256-bit hashes.  MySQL returns the hash
    -- value as a hexadecimal string, which means that each byte is
    -- represented as 2 characters.  Thus, 256 / 8 * 2 = 64.
    -- We can use BINARY or CHAR here; BINARY simply has a different
    -- definition for comparison/sorting than CHAR.
    password_hash CHAR(64) NOT NULL
);

-- [Problem 1a]

DELIMITER !
CREATE PROCEDURE add_to_user(name VARCHAR(80), dbusername VARCHAR(20))
BEGIN
    INSERT INTO user(user_id, name, username)
        VALUES (NULL, name, dbusername);
END !
DELIMITER ;

-- Adds a new user to the user_info table, using the specified password (max
-- of 20 characters). Salts the password with a newly-generated salt value,
-- and then the salt and hash values are both stored in the table.
DELIMITER !
CREATE PROCEDURE sp_add_user(username VARCHAR(20), password VARCHAR(20))
BEGIN
    -- generate salt
    DECLARE generated_salt CHAR(8) DEFAULT make_salt(8);
    
    -- prepend salt to password and generate SHA-2 hash 
    DECLARE generated_hash CHAR(64);
    SET generated_hash = SHA2(CONCAT(generated_salt, password), 256);
    
    -- Add a new record to the user_info table with the username, salt, and 
    -- salted password.
    INSERT INTO user_info(username, salt, password_hash) 
        VALUES (username, generated_salt, generated_hash);
    
    -- Adds new user to the user table from our DDL so that they can
    -- add items to their own personal closet and/or the collaborative closet.
    /* CALL add_to_user(username, username); */
END !
DELIMITER ;

-- [Problem 1b]
-- Authenticates the specified username and password against the data
-- in the user_info table.  Returns 1 if the user appears in the table, and the
-- specified password hashes to the value for the user. Otherwise returns 0.
DELIMITER !
CREATE FUNCTION authenticate(username VARCHAR(20), password VARCHAR(20))
RETURNS TINYINT DETERMINISTIC
BEGIN
    -- declare variables to hold database values for 
    -- salt & hashed password 
    DECLARE db_salt VARCHAR(8);
    DECLARE db_pw_hash CHAR(64);
    DECLARE generated_hash CHAR(64);
    
    -- check if username in user_info table
    IF (username NOT IN (
        SELECT username 
        FROM user_info)) 
      THEN RETURN 0;
    END IF;

    -- check if the provided password yields the same hash as the
    -- corresponding one in the database    
    
    -- get database user salt & hash 
    SELECT salt, password_hash INTO db_salt, db_pw_hash
    FROM user_info 
    WHERE user_info.username = username;

    -- prepend salt to password and generate SHA-2 hash 
    SET generated_hash = SHA2(CONCAT(db_salt, password), 256);
    
    -- check if hashed password matches the corresponding one in the database
    IF generated_hash = db_pw_hash 
      THEN RETURN 1;
    END IF;
    
    RETURN 0;
END !
DELIMITER ;

-- [Problem 1c]
-- Add at least two users into your user_info table so that when we run this file,
-- we will have examples users in the database.
CALL sp_add_user('emilypan', 'swimmerpenguin123');
CALL sp_add_user('bridgetyang', 'beyonce777');
CALL sp_add_user('ektapatel', 'futurederma02');

/* CALL add_to_user('Emily Pan', 'emilypan');
CALL add_to_user('Bridget Yang', 'bridgetyang');
CALL add_to_user('Ekta Patel', 'ektapatel'); */


-- [Problem 1d]
-- Optional: Create a procedure sp_change_password to generate a new salt and change the given
-- user's password to the given password (after salting and hashing)
DELIMITER !
CREATE PROCEDURE sp_change_password(username VARCHAR(20), password VARCHAR(20))
BEGIN
    -- generate salt
    DECLARE generated_salt VARCHAR(8) DEFAULT make_salt(8);
    
    -- update given user's password using new salt
    UPDATE user_info
    SET salt = generated_salt, 
        password_hash = SHA2(CONCAT(generated_salt, password), 256)
    WHERE user_info.username = username;
END !
DELIMITER ;