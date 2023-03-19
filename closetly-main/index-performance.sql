-- CS 121 
-- Final Project: Part B 
-- Scripts to test performance of indexing 

CREATE TABLE collab_unindexed (
    -- Uniquely identifies database user (the original owner 
    -- of the item)
    user_id           INTEGER, -- original owner
    clothing_id       INTEGER,
    curr_condition    VARCHAR(50), -- good, new, poor
    is_available      TINYINT DEFAULT 1 NOT NULL, -- 1 means available
    current_borrower  INTEGER, -- user_id of current borrower
    -- Each piece of clothing in the collaborative closet is identified
    -- by its original owner & clothing ID 
    PRIMARY KEY (user_id, clothing_id),
    -- All clothing in the collaborative closet must have been assigned
    -- a clothing_id upon entry and exist in a personal closet, 
    -- so must cascade
    FOREIGN KEY (clothing_id) 
        REFERENCES personal_closet(clothing_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    -- Only existing users can post and use clothes from the collaborative
    -- closet, so must cascade
    FOREIGN KEY (user_id)
        REFERENCES user(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- creates a duplicate of collab_closet that is not indexed 
LOAD DATA LOCAL INFILE 'final-project/collab_closet.csv' INTO TABLE collab_unindexed
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS
(user_id, clothing_id, curr_condition, is_available, current_borrower) 
SET current_borrower = NULLIF(current_borrower, -1);

-- test the performance difference between indexed and unindexed tables
SET profiling=1;

-- retreives all collaborative closet entries where either user 1 or 2 borrowed
-- a piece of clothing 
SELECT *
FROM collab_closet -- indexed
WHERE current_borrower = 1 OR current_borrower = 2;

SELECT *
FROM collab_unindexed -- not indexed
WHERE current_borrower = 1 OR current_borrower = 2;

SHOW PROFILES;