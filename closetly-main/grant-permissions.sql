DROP USER IF EXISTS 'appadmin'@'localhost';
DROP USER IF EXISTS 'appclient'@'localhost';
DROP USER IF EXISTS 'storeowner'@'localhost';
DROP USER IF EXISTS 'personal'@'localhost';
DROP USER IF EXISTS 'stylist'@'localhost';

CREATE USER 'appadmin'@'localhost' IDENTIFIED BY 'adminpw';
CREATE USER 'appclient'@'localhost' IDENTIFIED BY 'clientpw';
CREATE USER 'storeowner'@'localhost' IDENTIFIED BY 'storeownerpw';
CREATE USER 'stylist'@'localhost' IDENTIFIED BY 'stylistpw';
CREATE USER 'personal'@'localhost' IDENTIFIED BY 'personalpw';

-- Can add more users or refine permissions
GRANT ALL PRIVILEGES ON closetly.* TO 'appadmin'@'localhost';
GRANT SELECT ON closetly.* TO 'appclient'@'localhost';

-- store owners: should be able to view store closet and also update
-- for sales or new clothes. should NOT have any privileges relating
-- to personal or shared closets

GRANT SELECT, UPDATE, INSERT, DELETE ON closetly.store_closet TO 'storeowner'@'localhost';
GRANT SELECT, INSERT ON closetly.styled_outfits TO 'storeowner'@'localhost';
GRANT SELECT ON closetly.permissions TO 'storeowner'@'localhost';
GRANT SELECT ON closetly.user TO 'storeowner'@'localhost';
GRANT SELECT ON closetly.clothes TO 'storeowner'@'localhost';

GRANT EXECUTE ON PROCEDURE sp_add_user TO 'storeowner'@'localhost';
GRANT EXECUTE ON PROCEDURE add_to_user TO 'storeowner'@'localhost';
GRANT EXECUTE ON PROCEDURE sell_to_user TO 'storeowner'@'localhost';
GRANT EXECUTE ON FUNCTION find_original_price TO 'storeowner'@'localhost'

-- personal stylists: should have select privileges on store, collab
-- and personal closets, and should bave update and insert privileges
-- on outfits 

GRANT SELECT ON closetly.collab_closet TO 'stylist'@'localhost';
GRANT SELECT ON closetly.personal_closet TO 'stylist'@'localhost';
GRANT SELECT on closetly.store_closet TO 'stylist'@'localhost';
GRANT SELECT, UPDATE, INSERT ON closetly.styled_outfits TO 'stylist'@'localhost';
GRANT SELECT ON closetly.permissions TO 'stylist'@'localhost';
GRANT SELECT ON closetly.user TO 'stylist'@'localhost';
GRANT SELECT ON closetly.clothes TO 'stylist'@'localhost';

GRANT EXECUTE ON PROCEDURE sp_add_user TO 'stylist'@'localhost';
GRANT EXECUTE ON PROCEDURE add_to_user TO 'stylist'@'localhost';

-- regular people: should have all privileges on their own personal
-- closets, should be able to view and select from store closets,
-- should be able to view and update collaborative closet, as well
-- as create new outfits in styled_outfits 

GRANT SELECT, UPDATE, INSERT, DELETE ON closetly.personal_closet TO 'personal'@'localhost';
GRANT SELECT ON closetly.store_closet TO 'personal'@'localhost';
GRANT SELECT ON closetly.clothes TO 'personal'@'localhost';
GRANT SELECT, UPDATE ON closetly.collab_closet TO 'personal'@'localhost';
GRANT SELECT, UPDATE, INSERT ON closetly.styled_outfits TO 'personal'@'localhost';
GRANT SELECT ON closetly.permissions TO 'personal'@'localhost';
GRANT SELECT ON closetly.user TO 'personal'@'localhost';
GRANT SELECT ON closetly.clothes TO 'personal'@'localhost';

GRANT EXECUTE ON FUNCTION borrow_item TO 'personal'@'localhost';
GRANT EXECUTE ON PROCEDURE sp_add_user TO 'personal'@'localhost';
GRANT EXECUTE ON PROCEDURE add_to_user TO 'personal'@'localhost';

FLUSH PRIVILEGES;

