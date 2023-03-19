-- Returns the average clothing item price and discount for each store
-- in the database. (Equivalent to RA expression #1)
SELECT store_name, AVG(price) AS avg_price, 
  AVG(discount) AS avg_discount
FROM store_closet
GROUP BY store_name;

-- Returns information on any size S/4 clothes that are on sale
-- in any store. (Equivalent to RA expression #2)
SELECT store_name, clothing_id, clothing_type, price, color,
  brand, description, image_url
FROM clothes NATURAL JOIN store_closet
WHERE size = 'S' OR size = '4' AND discount > 0;

-- For each user part of the collaborative closet, returns how many 
-- of their clothing items are currently being borrowed by a friend.
-- (Equivalent to RA expression #3)
SELECT user_id, name, COUNT(*) AS num_clothes_loaning
FROM user NATURAL JOIN collab_closet
WHERE current_borrower != -1
GROUP BY user_id;

-- Returns total price of all styled outfits composed only of
-- items being sold in a store.
SELECT outfit_id, SUM(price) AS total_price
FROM styled_outfits NATURAL JOIN store_closet
GROUP BY outfit_id;

-- Return Bridget's clean clothing items that are part of a styled
-- outfit.
SELECT clothing_id, clothing_type, gender, size, color, brand,
  description, image_url, aesthetic
FROM clothes NATURAL JOIN personal_closet
WHERE user_id = 2 AND clean = 1 AND
  clothing_id IN (
    SELECT clothing_id FROM styled_outfits
  );

-- Return outfits that consist of at least one item currently on sale.
-- (Equivalent to RA expression #4) 
SELECT outfit_id, outfit_desc, vibe
FROM styled_outfits
WHERE clothing_id IN (
  SELECT clothing_id FROM store_closet
  WHERE discount > 0
);

-- Insert a new outfit into styled_outfits. (Equivalent to RA 
-- expression #5)
INSERT INTO styled_outfits VALUES
  (7, 4, "All Lululemon women's athletic outfit for colder weather", 
   "sporty"),
  (7, 12, "All Lululemon women's athletic outfit for colder weather", 
   "sporty"),
  (7, 13, "All Lululemon women's athletic outfit for colder weather", 
   "sporty");

-- Emily decided that she no longer wants to loan out her Levi's 
-- jeans so must delete from collab_closet and update the
-- corresponding share attribute in personal_closet.
-- (Equivalent to RA expression #6)
DELETE FROM collab_closet WHERE user_id = 1 AND clothing_id = 38;
UPDATE personal_closet
  SET shared = 0
  WHERE user_id = 1 AND clothing_id = 38;