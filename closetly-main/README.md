# closetly
README -
This is the final project for CS 121 Relational Databases at Caltech.
The goal of the project was to create a database to allow personal users, 
storeowners, and stylists to view their closets/inventories, borrow
clothes with others, sell clothes, and style outfits. 
The database supports a certain number of command-line queries as well as
employee and customer logins. Follow the instructions below to try it out
for yourself. Thank you!

Contributors: Bridget Yang, Emily Pan

Data source: 
- Initial data was created by us, as well as some entries
  taken from lululemon.com, freepeople.com,
  urbanoutfitters.com and zara.com 

Instructions for loading data on command-line:
Make sure you have MySQL downloaded and available through your
device's command-line.

First, create an appropriate database in mySQL:

mysql> CREATE DATABASE closetly;
mysql> USE closetly;


Not including the "mysql>" prompt, run the following lines of code on your command-line
after creating and using an appropriate database:

mysql> source setup-closetly.sql;
mysql> source load-data.sql;
mysql> source setup-passwords.sql;
mysql> source setup-routines.sql;
mysql> source setup-permissions.sql;
mysql> source grant-permissions.sql;
mysql> source queries.sql;

Instructions for Python program:
Please install the Python MySQL Connector using pip3 if not installed already.

After loading the data and verifying you are in the correct database, 
run the following to open the python application:

mysql> quit;

$ python3 app.py

If you are new to the app, please follow the prompts to create a new
user and let us know what type of user you are. We suggest that you
use a personal account if you plan to document your own closet and 
share clothes with others (and borrow from others!). We suggest that
you open a store owner account if you are a shop owner who wishes
to track and advertise your items and sell to other users. We suggest
that you select a stylist account if your primary purpose is to
put together outfits. 

Here is an introductory guide to using Closetly: 
    1. When you enter the app, you will be asked to enter a username. If 
       you already hold an account, enter your existing username. Otherwise,
       to create a new account, enter in a new username to be used as the
       username to your new account. 
    2. If you have an existing account, enter your login credentials and 
       enjoy our app! 
    3. If you are making a new account, answer the prompts for your name and
       account password. Let us know what type of account you'd like to open!
       Once you have completed the setup, you should be able to use our app. 

Here is a suggested guide to using Closetly as personal user:
    1.  Select option [a] to see all the clothes in your closet.
    2.  Select option [b] to see all the clothes in the collaborative
        (shared) closet. Note down the clothing_id values of all
        the clothes you are interested in borrowing! 
    3.  Select option [c] to borrow an item from the collaborative closet.
        Use the clothing_id numbers you remembered from (2.). 
    4.  Select option [d] to style an outfit. To do this, you must enter
        the clothing_id numbers of the pieces that make up this outfit
        separated by spaces. For example, if I wanted to create an outfit
        with pieces numbered 1, 2, and 4, I would type in "1 2 4" when
        prompted. You can also add an outfit description if you would like.
    5.  Select option [q] to quit the menu.

Here is a suggested guide to using Closetly as a store owner:
    1.  Select option [a] to view all the items of clothing in your inventory.
        Note: you can also use filters by price, clothing type, and discount
              on your store inventory.
    2.  Select option [b] to add an item to your store inventory.
    3.  Select option [c] to remove an item from your store inventory.
    4.  Select option [s] to sell an item from your store to another user
        with a personal account in Closetly.
    5.  Select option [e] to change the discount percentage of an item.
    6.  Select option [q] to quit the menu. 

Here is a suggested guide to using Closetly as a stylist:
    1.  Select option [a] to show all the clothes in the collaborative closet.
    2.  Select option [b] to show all the inventory of all the stores available.
        You can filter by price, clothing type, and discount. 
    3.  Select option [c] to create an outfit. To do this, you must enter
        the clothing_id numbers of the pieces that make up this outfit
        separated by spaces. For example, if I wanted to create an outfit
        with pieces numbered 1, 2, and 4, I would type in "1 2 4" when
        prompted. You can also add an outfit description if you would like.
    4.  Select option [q] to quit the menu.

Files written to user's system:
- No files are written to the user's system.

Unfinished features:
- As a store owner, we created functionality to find the original price of an
  item before it was discounted in the case that you would like to revert a
  sale or a promotion ends. This is the only function that we know of that does
  not work as intended, and we are working to patch this as soon as possible.
- Asthetic improvements, printing out more detailed errors when invalid actions
  are attempted by users.