-- Load all clothing item data into the clothes table.
LOAD DATA LOCAL INFILE 'clothes.csv' INTO TABLE clothes
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS;

-- Load all user data into the user table.
LOAD DATA LOCAL INFILE 'user.csv' INTO TABLE user
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS;

-- Load all users' personal closet data into the personal_closet table.
-- If the user does not enter how many times they wore a clothing item,
-- default to the integer -1 (NULL).
LOAD DATA LOCAL INFILE 'personal_closet.csv' INTO TABLE personal_closet
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS
(user_id, clothing_id, is_clean, shared, num_wears) 
SET num_wears = NULLIF(num_wears, -1);

-- Load all stores' (clothes.store_name != NULL) inventory data into the 
-- store_closet table.
LOAD DATA LOCAL INFILE 'store_closet.csv' INTO TABLE store_closet
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS;

-- Load all data into the collab_closet for items that users are willing
-- to share (personal_closet.shared = 1) from their personal closet. If no one is
-- currently borrowing a shareable item, set its current borrower ID to -1 (NULL).
LOAD DATA LOCAL INFILE 'collab_closet.csv' INTO TABLE collab_closet
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS
(user_id, clothing_id, curr_condition, is_available, current_borrower) 
SET current_borrower = NULLIF(current_borrower, -1);

-- Load all data for each styled outfit into the styled_outfits table.
LOAD DATA LOCAL INFILE 'styled_outfits.csv' INTO TABLE styled_outfits
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS;
