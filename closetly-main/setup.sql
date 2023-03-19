-- CS 121
-- Final Project: Introduction to SQL
-- Setup file for defining and loading closet data

-- Clean up old tables
DROP TABLE IF EXISTS styled_outfits;
DROP TABLE IF EXISTS collab_closet;
DROP TABLE IF EXISTS store_closet;
DROP TABLE IF EXISTS personal_closet;
DROP TABLE IF EXISTS clothes;
DROP TABLE IF EXISTS user;

-- Stores information about all the users of the database
-- that have a closet (including as those that borrow clothes)
CREATE TABLE user (
    -- Uniquely identifies database user 
    user_id           INTEGER AUTO_INCREMENT,
    -- Can be a person's name (first and last) or store name:
    name              VARCHAR(80) NOT NULL,
    -- A given username can have multiple accounts and thus
    -- multiple user_id's. For example, a user can have an account
    -- for their personal use and another account for their store.
    username          VARCHAR(20),
    PRIMARY KEY (user_id)
);

-- Stores information about each piece of clothing entered
-- by users for their personal, collaborative, or store closet
CREATE TABLE clothes (
    -- Uniquely defines each piece of clothing in the database
    clothing_id       INTEGER AUTO_INCREMENT,
    clothing_type     VARCHAR(100) NOT NULL, -- jacket, shoes, skirt, etc.
    size              VARCHAR(20) NOT NULL, -- could be S, small, 4, etc.
    gender            CHAR(1), -- gender: W, M, U 
    color             VARCHAR(50),
    brand             VARCHAR(150),
    description       VARCHAR(250),    
    image_url         VARCHAR(250),
    aesthetic         VARCHAR(200), 
    store_name        VARCHAR(100), -- if part of a store inventory
    PRIMARY KEY (clothing_id)
);

-- Stores all the information about the clothes in a user's 
-- personal closet 
CREATE TABLE personal_closet (
    -- Uniquely identifies database user (the closet owner)
    user_id        INTEGER,
    -- Uniquely defines each piece of clothing in the database
    clothing_id    INTEGER,
    is_clean       TINYINT DEFAULT 1, -- 1 means clean
    -- 0 means that the user does not want to share the item
    shared         TINYINT DEFAULT 0 NOT NULL,
    num_wears      INTEGER,
    -- The user and clothing ID's uniquely identify each piece 
    -- of clothing in the closet 
    PRIMARY KEY (user_id, clothing_id),
    -- A personal closet depends on the existence of a user, so must cascade
    FOREIGN KEY (user_id)
        REFERENCES user(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    -- All clothing in a closet must have been assigned a clothing_id
    -- upon entry, so must cascade 
    FOREIGN KEY (clothing_id)
        REFERENCES clothes(clothing_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Stores all the information about clothes available for 
-- sharing in the collaborative closet 
CREATE TABLE collab_closet (
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

-- Stores all the information about the clothes available for
-- sale in a store's closet 
CREATE TABLE store_closet (
    store_name        VARCHAR(100), 
    -- Uniquely defines each piece of clothing in the database
    clothing_id       INTEGER,
    -- cost of piece in USD, e.g. $52.10
    price             NUMERIC(10, 2) NOT NULL,
    discount          DECIMAL(4, 1) NOT NULL, -- percent discount, e.g. 35.2% off
    PRIMARY KEY (store_name, clothing_id),
    -- Only existing clothing items can be part of a store's inventory, so
    -- must cascade
    FOREIGN KEY (clothing_id) 
        REFERENCES clothes(clothing_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Stores outfits created by clothing items in one or more closets
CREATE TABLE styled_outfits (
    outfit_id       INTEGER,
    -- Uniquely defines each piece of clothing in the database
    clothing_id     INTEGER,
    outfit_desc     VARCHAR(250),
    vibe            VARCHAR(250),
    -- Multiple clothing items can be a part of the same outfit
    PRIMARY KEY (outfit_id, clothing_id),
    -- Only existing clothing items can be part of an outfit, so
    -- must cascade
    FOREIGN KEY (clothing_id)
        REFERENCES clothes(clothing_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Creates an index on the current borrowers of a collaborative closet
CREATE INDEX idx_borrower 
    ON collab_closet (current_borrower);
