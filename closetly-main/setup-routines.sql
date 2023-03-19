-- Clean up old tables
DROP FUNCTION IF EXISTS find_original_price;
DROP FUNCTION IF EXISTS find_available;
DROP PROCEDURE IF EXISTS sell_to_user;
DROP FUNCTION IF EXISTS borrow_item;
DROP TRIGGER IF EXISTS condition_update;

-- Given a clothing item's discounted price and original discount, find
-- the original price of the clothing item 
DELIMITER !
CREATE FUNCTION find_original_price (price NUMERIC(10,2), discount DECIMAL(4,1))
RETURNS NUMERIC(10,2) DETERMINISTIC
BEGIN
    IF discount = 0 THEN 
        RETURN price;
    ELSE 
        RETURN (price / discount);
    END IF;
END !
DELIMITER ;

-- Given a clothng type, color, and size, returns if item meeting desired criteria
-- is available in personal or shared closet. 
DELIMITER ! 
CREATE FUNCTION find_available (clothing_type VARCHAR(100), size VARCHAR(20), 
    color VARCHAR(50)) 
RETURNS TINYINT DETERMINISTIC
BEGIN
    -- Checks if any of the clothing ID's of clothing items that meet the
    -- desired criteria are in the personal or shared closet. This is
    -- determined by if the clothing is in the intersection between
    -- similar clothes in the entire clothes database and clothes available
    -- to the user is not an empty set.
    IF IS_EMPTY(
        -- Gets the set of all clothing ID's that are both the same as what
        -- the user is looking for and also exist in the personal and/or
        -- shared closets.
        SELECT * FROM
            -- Finds all clothing ID's of the same type, size, and color given.
            ((SELECT clothing_id FROM clothes
             WHERE clothes.clothing_type = clothing_type AND clothes.size = size
             AND clothes.color = color) AS desired
             NATURAL JOIN
             -- Finds all clothing ID's in the shared or personal closets
             -- by finding the union of the personal and collaborative closets.
             (SELECT * FROM (
                -- Gets all clothing ID's from personal closet
                SELECT clothing_id FROM personal_closet AS personal
                -- Gets all clothing ID's from collaborative closet
                UNION 
                SELECT clothing_id FROM collab_closet AS collab) AS avail) AS inter)
    ) THEN RETURN 0;
    RETURN 1;
    END IF;
END !
DELIMITER ;

-- Procedure to remove an item from store closet and add it to
-- a personal closet when a store sells an item of clothing to a user.
DELIMITER !
CREATE PROCEDURE sell_to_user (sold_clothing_id INTEGER, buyer_user_id INTEGER) 
BEGIN 
    DELETE FROM store_closet WHERE clothing_id = sold_clothing_id LIMIT 1;
    INSERT INTO personal_closet VALUES (buyer_user_id, sold_clothing_id,1,0,0);
END !
DELIMITER ;

-- Function to check if a specific clothing item is available to borrow
-- from the collaborative closet. If it is available and the potenital borrower
-- is not the original owner of the item, then borrow it.
DELIMITER !
CREATE FUNCTION borrow_item (potential_borrower_id INTEGER, clothing_id INTEGER)
RETURNS TINYINT DETERMINISTIC
BEGIN
    DECLARE is_avail TINYINT;
    -- need to make sure you're not borrowing from yourself
    DECLARE item_owner INTEGER;

    SELECT user_id, is_available INTO item_owner, is_avail
    FROM collab_closet AS c
    WHERE c.clothing_id = clothing_id;

    IF (is_avail = 1 AND item_owner <> potential_borrower_id) THEN
        UPDATE collab_closet
            SET is_available = 0, current_borrower = potential_borrower_id
            WHERE collab_closet.clothing_id = clothing_id;
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END !
DELIMITER ;


-- Trigger to update clothing item condition to 'used' after 50 wears 
DELIMITER !
CREATE TRIGGER condition_update AFTER UPDATE
    ON personal_closet FOR EACH ROW
BEGIN
    IF NEW.num_wears > 50 THEN
        IF (curr_condition = 'new' OR ISNULL(curr_condition)) THEN
            UPDATE collab_closet 
            SET curr_condition = 'used'
            WHERE collab_closet.clothing_id = 
                    personal_closet.clothing_id;
        END IF;
    END IF;
END !
DELIMITER ;