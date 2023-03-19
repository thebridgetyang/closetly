"""
Python app to interface with Closetly MySQL database
"""
import sys  # to print error messages to sys.stderr
import mysql.connector
# To get error codes from the connector, useful for user-friendly
# error-handling
import mysql.connector.errorcode as errorcode
import pandas as pd # cleans up output + adds some extra python functionality

# Debugging flag to print errors when debugging that shouldn't be visible
# to an actual client. Set to False when done testing.
DEBUG = False # MAKE FALSE WHEN SUBMITTING  

def get_conn(user, password):
    """"
    Returns a connected MySQL connector instance, if connection is successful.
    If unsuccessful, exits.
    """
    try:
        conn = mysql.connector.connect(
          host='localhost',
          user=user,
          # Find port in MAMP or MySQL Workbench GUI or with
          # SHOW VARIABLES WHERE variable_name LIKE 'port';
          port='3306',
          password=password,
          database='closetly'
        )
        if DEBUG:
            print('Successfully connected.')
        return conn
    except mysql.connector.Error as err:
        # Remember that this is specific to _database_ users, not
        # application users. So is probably irrelevant to a client in your
        # simulated program. Their user information would be in a users table
        # specific to your database.
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR and DEBUG:
            sys.stderr('Incorrect username or password when connecting to DB.')
        elif err.errno == errorcode.ER_BAD_DB_ERROR and DEBUG:
            sys.stderr('Database does not exist.')
        elif DEBUG:
            sys.stderr(err)
        else:
            sys.stderr('An error occurred, please contact the administrator.')
        sys.exit(1)

# ----------------------------------------------------------------------
# Functions for Logging Users In
# ----------------------------------------------------------------------
def check_username(username):
    """
    Checks if a username already exists in the app. 
    Returns True if it already exists, False if it is a new username.
    """
    # access user_info to obtain the set of all usernames available
    sql = "SELECT COUNT(*) FROM (SELECT username FROM user_info" +\
          " WHERE username='" + username + "') as matches;"
    cursor = conn.cursor(buffered=True)
    cursor.execute(sql)
    # check if the given username exists in the username table
    # return true if it does exist and false if not
    a=cursor.fetchone()[0]
    return bool(a)
    # return bool(cursor.fetchone()[0])

def authenticate_login(username, password):
    """
    Authenticates login by matching the username and password with the
    encrypted passwords. 
    """
    sql = 'SELECT authenticate (%s, %s);'
    cursor = conn.cursor()
    cursor.execute(sql, (username, password))
    return bool(cursor.fetchone()[0])

def add_user(name, username, password):
    """
    Calls SQL procedures to add a new user to the database as well
    as binding passwords to the username. 
    """
    cursor = conn.cursor()
    cursor.callproc('sp_add_user', args=(username, password))
    conn.commit()
    cursor.callproc('add_to_user', args=(name, username))
    conn.commit()
    return username

def get_account_type():
    """
    Prompts use for the type of account type that they would like to 
    open and returns the database user name. 
    """
    # figure out what type of account the user is trying to get
    print("Account types: ")
    print("(a) Store Owner")
    print("(b) Stylist")
    print("(c) Personal Use")
    ans = input("Enter account type: ")[0].lower()
    if ans == 'a':
        return 'storeowner'
    elif ans == 'b':
        return 'stylist'
    else:
        return 'personal'

def change_connection(account_type):
    """
    Given the account type (personal, stylist, store owner, admin) of a user,
    changes the connection so that the right privileges are granted. 
    """
    # changes connection based on permission level
    conn.close()
    if account_type == 'storeowner':
        return get_conn('storeowner', 'storeownerpw')
    elif account_type == 'stylist':
        return get_conn('stylist', 'stylistpw')
    elif account_type == 'personal':
        return get_conn('personal', 'personalpw')
    elif account_type == 'admin':
        return get_conn('appadmin', 'adminpw')
    else: 
        # give general 'appclient' privileges
        return get_conn('personal', 'personalpw')

def get_permission(username):
    """
    Gets the user type (personal, stylist, store owner, or admin) of the
    given user based on the username.  
    """
    sql = "SELECT role FROM permissions WHERE username='"+username+"';"
    cursor = conn.cursor()
    cursor.execute(sql)
    # check if the given username exists in the username table
    # return true if it does exist and false if not
    return cursor.fetchone()[0]

def login():
    """
    Login function for the Closetly app. 
    Takes user input for the username, and prompts for the password to log
    the user in or prompts for additional information to create a new 
    account. 
    Updates the connection based on what user type has logged in. 
    """
    # conn = get_conn('appadmin', 'adminpw')
    username = input("Enter username: ")
    valid_username = check_username(username)
    global conn
    if valid_username == True:
        # initiate password authentication & continue 
        password = input("Enter password: ")
        if authenticate_login(username, password): # authenticated 
            # change connection type 
            perma = get_permission(username)
            print(perma)
            conn = change_connection(perma)
            return username
        print("Incorrect login")
        quit_ui()
    else:
        # prompt to create new account
        create_new_acc = input("Would you like to create an account? [Y/N]\n")
        if create_new_acc.upper() == 'Y':
            name = input('What is your name (first and last)?\n')

            if len(username) > 20:
                username = input('Username is too long. \
                                  Must be 20 characters or less.\n')
                return login()

            # handle different account types
            account_type = get_account_type()
            # add account type to user information
            cursor = conn.cursor()
            cursor.callproc('user_add_permission', \
                            args=(username, account_type))
            conn.commit()
            # change connection to the correct user 
            conn = change_connection(account_type)

            new_password = input("What would you like your password to be?\n")
            while len(new_password) > 20:
                new_password = input('Password is too long. Must be 20 \
                                      characters or less:\n')
            add_user(name, username, new_password)
            return username
            
        elif create_new_acc.upper() == 'N':
            print('Have a nice day!')
            quit_ui()
        else:
            print('Sorry, this is not a valid response :( Please try again.')
            login()
        # if yes: add to user_info and login 
        # if no: quit

# ----------------------------------------------------------------------
# Functions for Command-Line Options/Query Execution
# ----------------------------------------------------------------------

def show_all_clothes():
    """
    Shows a list of all the clothing in the database. Includes all clothes
    from every personal, collaborative, and store closet.
    """
    print('This is all the clothing items in the personal, collaborative, ' + \
          'and store closets:\n')
    sql = 'SELECT * FROM clothes;'
    cursor = conn.cursor()
    cursor.execute(sql)
    rows = cursor.fetchall()
    df = pd.DataFrame(rows, columns=['clothing_id','clothing_type','size',\
                                     'gender','color','brand','description',\
                                     'image_url','aesthetic','store_name'])
    print(df)

def show_personal_clothes(username):
    """
    Shows a list of all the clothing in the user's personal closet.
    """
    print('This is all the clothing items in your personal closet:\n')
    sql = """SELECT clothing_id, clothing_type, size, gender, color, brand,
           description, image_url, aesthetic, is_clean, shared, num_wears
           FROM clothes NATURAL JOIN personal_closet NATURAL JOIN user
           WHERE username = '""" + username + "';"
    cursor = conn.cursor()
    cursor.execute(sql)
    rows = cursor.fetchall()
    df = pd.DataFrame(rows, columns=['clothing_id','clothing_type','size',\
                                     'gender','color','brand','description',\
                                     'image_url','aesthetic','is_clean',\
                                     'shared', 'num_wears'])
    print(df)

def borrow_from_collab_closet(user_id):
    """
    Lets a user borrow a clothing item from the collaborative closet
    if they are not the original owner and it is not currently being 
    borrowed by someone else.
    """
    clothing_id = input("What is the clothing ID of the item you " + \
                        "would like to borrow?\n")
    sql = 'SELECT borrow_item(%s, %s);'
    cursor = conn.cursor(buffered=True)
    cursor.execute(sql, (user_id, clothing_id))
    res = cursor.fetchone()[0]
    if res == 1:
        print('Item successfully borrowed!')
    else:
        print('Sorry, you cannot borrow this item :(')

def show_collaborative_clothes():
    """
    Shows a list of all the clothing in the collaborative closet.
    """
    print('This is all the clothing items you can borrow from the' + \
          ' colaborative closet:\n')
    sql = """SELECT user_id, clothing_id, clothing_type, size, gender, color, \
             brand, description, image_url, aesthetic, curr_condition, \
             is_available, current_borrower
             FROM collab_closet NATURAL JOIN clothes;"""
    cursor = conn.cursor()
    cursor.execute(sql)
    rows = cursor.fetchall()
    df = pd.DataFrame(rows, columns=['user_id','clothing_id','clothing_type',\
                                     'size','gender','color','brand',\
                                     'description','image_url','aesthetic',\
                                     'curr_condition','is_available',\
                                     'current_borrower'])
    print(df)

def show_user_in_collab(user_id):
    """
    Shows all the clothing a specific user is loaning in the collaborative
    closet.
    """
    print('This is all the clothing items ' + user_id\
           + ' has in the colaborative' + ' closet:\n')
    sql = """SELECT clothing_id, clothing_type, size, gender, color,
           brand, description, image_url, aesthetic, curr_condition,
           is_available, current_borrower
           FROM collab_closet NATURAL JOIN clothes 
           WHERE user_id = '""" + user_id + "';"
    cursor = conn.cursor()
    cursor.execute(sql)
    rows = cursor.fetchall()
    df = pd.DataFrame(rows, columns=['clothing_id','clothing_type','size',\
                                     'gender','color','brand','description',\
                                     'image_url','aesthetic','curr_condition',\
                                     'is_available','curr_borrower'])
    print(df)

def show_store_inventory(store_name):
    """
    Shows a list of all the clothing in the given store's inventory.
    """
    print('This is all the clothing items currently being sold at '\
           + store_name + ':\n')
    sql = """SELECT clothing_id, price, discount, clothing_type, size, 
           gender, color, brand, description, image_url, aesthetic 
           FROM store_closet NATURAL JOIN clothes
           WHERE store_name = '""" + store_name + "';"
    cursor = conn.cursor()
    cursor.execute(sql)
    rows = cursor.fetchall()
    df = pd.DataFrame(rows, columns=['clothing_id','price', 'discount',\
                                     'clothing_type','size','gender','color',\
                                     'brand','description','image_url',\
                                     'aesthetic'])
    print(df)

def filter_store_by_price(store_name, min_price, max_price):
    """
    Shows a list of all the clothing being sold in the provided price range
    in a given store.
    """
    print('This is all the clothing items currently being sold at '\
           + store_name + 'for under $' + max_price + ':\n')
    sql = """SELECT clothing_id, price, discount, clothing_type, size,
           gender, color, brand, description, image_url, aesthetic 
           FROM store_closet NATURAL JOIN clothes
           WHERE store_name='""" + store_name + "' AND price <= '" + max_price +\
           "' AND price >= '" + min_price + "' ORDER BY price;"
    cursor = conn.cursor()
    cursor.execute(sql)
    rows = cursor.fetchall()
    df = pd.DataFrame(rows, columns=['clothing_id','price', 'discount',\
                                     'clothing_type','size','gender','color',\
                                     'brand','description','image_url',\
                                     'aesthetic'])
    print(df)

def filter_store_by_type(store_name, clothing_type):
    """
    Shows a list of all the clothing of a certain type (sweatshirt, dress, etc.)
    in a given store.
    """
    print('This is all the clothing items of the type (' + clothing_type + \
          ') currently being sold at' + store_name + ':\n')
    sql = """SELECT clothing_id, price, discount, clothing_type, size,
           gender, color, brand, description, image_url, aesthetic 
           FROM store_closet NATURAL JOIN clothes
           WHERE clothing_type = '""" + clothing_type + "';"
    cursor = conn.cursor()
    cursor.execute(sql)
    rows = cursor.fetchall()
    df = pd.DataFrame(rows, columns=['clothing_id','price', 'discount',\
                                     'clothing_type','size','gender','color',\
                                     'brand','description','image_url',\
                                     'aesthetic'])
    print(df)

def filter_store_by_discount(store_name, min_discount, max_discount):
    """
    Shows a list of all the clothing items being solid within a given discount
    range in a given store.
    """
    print('This is all the clothing items currently being sold in the' +\
          ' designated discount range at ' + store_name + ':\n')
    sql = """SELECT clothing_id, price, discount, clothing_type, size,
           gender, color, brand, description, image_url, aesthetic 
           FROM store_closet NATURAL JOIN clothes
           WHERE discount >= '""" + min_discount + "' AND discount <= '"\
           + max_discount + "' ORDER BY discount;"
    cursor = conn.cursor()
    cursor.execute(sql)
    rows = cursor.fetchall()
    df = pd.DataFrame(rows, columns=['clothing_id','price', 'discount',\
                                     'clothing_type','size','gender','color',\
                                     'brand','description','image_url',\
                                     'aesthetic'])
    print(df)

def check_outfit_id(id):
    """
    Checks if the outfit id already exists in the database. 
    Returns True if it does exist, False if it does not. 
    """
    # access styled_outfits to obtain the set of all usernames available
    sql = "SELECT COUNT(*) FROM (SELECT DISTINCT outfit_id FROM"\
           + " styled_outfits WHERE outfit_id='"\
           + id + "') as matches;"
    cursor = conn.cursor(buffered=True)
    cursor.execute(sql)
    # check if the given outfit id exists in the styled_outfits table
    # return true if it does exist and false if not
    a=cursor.fetchone()[0]
    return bool(a)

def create_outfit():
    """
    Lets any user create an outfit using clothes from their own personal
    closet, the collaborative closet, and/or every store.
    """
    clothing_ids = list(map(int, input("Let's style an outfit! What are " +
                                       "the clothing ID's of the pieces " +
                                       "you would like it to consist of? " +
                                       "Separate them with spaces (e.g. 1 2 4)"
                                       + "\n").split()))
    while True:
      outfit_id = input('Assign an outfit ID (integer) to this outfit: ')
      if not check_outfit_id(outfit_id):
          break
    description = input('How would you describe this outfit? '\
                         + '(250 characters or less)\n')
    vibe = input('What is the "vibe" of this outfit? ' +
                 '(i.e.: business casual, going out, etc.)\n')
    for clothing_id in clothing_ids:
        sql = "INSERT INTO styled_outfits (outfit_id, clothing_id, outfit_desc,\
               vibe) VALUES ('" + str(outfit_id) + "', '" + str(clothing_id) + \
               "', '" + description + "', '" + vibe + "');"
        cursor = conn.cursor()
        cursor.execute(sql)
    new_sql = 'SELECT * FROM styled_outfits'
    cursor.execute(new_sql)
    rows = cursor.fetchall()
    df = pd.DataFrame(rows, columns=['outfit_id', 'clothing_id',\
                                     'outfit_des', 'vibe'])
    print(df)

def change_sale(username, clothing_id, new_discount):
    """
    Change the discount and thus price of a specific clothing item 
    in the store inventory.
    """
    # Different stores could be selling the same clothing item for
    # different prices, so must check that you're obtaining the 
    # price for the item from right store:
    get_price_discount = "SELECT price, discount FROM store_closet \
                          WHERE clothing_id = '" + clothing_id \
                          + "' AND store_name = '" + username + "';"
    cursor = conn.cursor(buffered=True)
    cursor.execute(get_price_discount)
    row = cursor.fetchone()
    old_price = row[0]
    old_discount = row[1]
    get_orig_price = "SELECT find_original_price(%s, %s);"
    cursor = conn.cursor(buffered=True)
    cursor.execute(get_orig_price, (old_price, old_discount))
    orig_price = cursor.fetchone()[0]
    new_price = float(orig_price) * (float(new_discount) / 100)
    sql = "UPDATE store_closet SET price = '" + str(round(new_price, 2)) \
          + "', discount = '" + new_discount \
          + "' WHERE clothing_id = '" + clothing_id \
          + "' AND store_name = '" + username + "';"
    cursor.execute(sql)
                   

# ----------------------------------------------------------------------
# Command-Line Functionality
# ----------------------------------------------------------------------
def show_options(username):
    """
    Redirects the program to show the options based on what type of
    user is using the program (store owner, stylist, or personal user).
    """
    permission = get_permission(username)
    if permission == 'storeowner':
        show_storeowner_options(username)
    elif permission == 'stylist':
        show_stylist_options(username)
    elif permission == 'personal':
        show_personal_options(username)
    elif permission == 'appadmin':
        show_admin_options(username)
    else: 
        show_personal_options(username)

def show_admin_options(username):
    """
    Show all the possible functionalities of the admin type user.
    They are unique because they have all the functionalities of the
    other three types (personal, store owner, and stylist) and are
    able to access the functionalities of all of the other types.
    """
    print('Admin options: ')
    print('  (a) Personal options')
    print('  (b) Store owner options')
    print('  (c) Stylist options')
    print('  (q) - quit')

    while True: 
        action = input('Enter an option: ')[0].lower()
        if action == 'a':
            show_personal_clothes(username)
        elif action == 'b':
            show_storeowner_options(username)
        elif action =='c':
            show_stylist_options(username)
        else:
            quit_ui()

def show_personal_options(username):
    """
    Show all the possible functionalities of the personal type user.
    They are unique because they have their own personal closet and can
    add and borrow from the collaborative closet. They can also browse
    every store's inventory.
    """
    print('Client options: ')
    print('  (a) show personal clothes')
    print('  (b) show collaborative clothes')
    print('  (c) borrow from collaborative closet')
    print('  (d) style an outfit')
    print('  (e) show store inventories')
    print('  (q) quit')

    while True: 
        action = input('Enter an option: ')[0].lower()
        if action == 'a':
            show_personal_clothes(username)
        elif action == 'b':
            show_collaborative_clothes()
            user_id = input('Enter the user_id of a specific user whose ' + \
                             'available ' + 'clothes you would like to see: ')
            show_user_in_collab(user_id)
        elif action == 'c':
            sql = "SELECT user_id FROM user WHERE username='" + username + "';"
            cursor = conn.cursor(buffered=True)
            cursor.execute(sql)
            res = cursor.fetchone()[0]
            user_id = int(res)
            print(user_id)
            borrow_from_collab_closet(user_id)
        elif action == 'd':
            create_outfit()
        elif action == 'e':
            store_name = input('Enter a store name: ')
            show_store_inventory(store_name)
            filter = input('Would you like to filter by price (p), clothing '\
                            + 'type (t), or discount (d)? ')
            if filter == 'p':
                min_price = input('Minimum price (in USD): $')
                max_price = input('Maximum price (in USD): $')
                filter_store_by_price(store_name, min_price, max_price)
            elif filter == 't':
                clothing_type = input('Clothing type: ')
                filter_store_by_type(store_name, clothing_type)
            elif filter == 'd':
                min_discount = input('Minimum discount (%): ')
                max_discount = input('Maximum disocunt (%): ')
                filter_store_by_discount(store_name, min_discount, max_discount)
        else:
            quit_ui()

def show_storeowner_options(username):
    """
    Show all the possible functionalities of the store owner user.
    The store owner is unique because they can add, remove, and modify
    their store inventory. However, they do not directly participate in
    the personal or collaborative closets, but they can sell clothing
    items to individuals who do.
    """
    print('Store Owner options: ')
    print('  (a) show inventory')
    print('  (b) add item to inventory')
    print('  (c) remove item from inventory')
    print('  (s) sell clothing item to user')
    print('  (e) change discount on item')
    print('  (q) quit')

    while True:
        action = input('Enter an option: ')[0].lower()
        if action == 'a':
            # store owner's username is just the store name
            show_store_inventory(username)
            filter = input('Would you like to filter by price (p), '\
                            + 'clothing type (t), or discount (d)? ')
            if filter == 'p':
                min_price = input('Minimum price (in USD): $')
                max_price = input('Maximum price (in USD): $')
                filter_store_by_price(username, min_price, max_price)
            elif filter == 't':
                clothing_type = input('Clothing type: ')
                filter_store_by_type(username, clothing_type)
            elif filter == 'd':
                min_discount = input('Minimum discount (%): ')
                max_discount = input('Maximum disocunt (%): ')
                filter_store_by_discount(username, min_discount, max_discount)
        elif action == 'b':
            clothing_id = input('Clothing ID: ')
            price = input('Price of item: $')
            discount = input('Discount (%): ')
            sql = "INSERT INTO store_closet VALUES ('" + username + "', "\
                  + str(clothing_id) + ", " + str(price) + ", "\
                  + str(discount) + ");"
            cursor = conn.cursor(buffered=True)
            cursor.execute(sql)
        elif action == 'c':
            clothing_id = input('Clothing ID of item you want to remove: ')
            sql = "DELETE FROM store_closet WHERE clothing_id = '" +\
                  clothing_id + "' AND store_name = '" + username +"';"
            cursor = conn.cursor(buffered=True)
            cursor.execute(sql)
        elif action == 's':
            clothing_id = input('Clothing ID of item being sold: ')
            user_id = input('User ID of user the item is being sold to: ')
            sql = 'CALL sell_to_user(%s, %s);'
            cursor = conn.cursor(buffered=True)
            cursor.execute(sql, (clothing_id, user_id))
        elif action == 'e':
            clothing_id = input('Clothing ID of item: ')
            new_discount = input('Desired discount (%): ')
            change_sale(username, clothing_id, new_discount)
        else:
            quit_ui()

def show_stylist_options(username):
    """
    Show all the possible functionalities of the stylist user.
    """
    print('Stylist options: ')
    print('  (a) show collaborative clothes')
    print('  (b) show store inventories')
    print('  (c) style an outfit for anyone')
    print('  (q) quit')

    while True: 
        action = input('Enter an option: ')[0].lower()
        if action == 'a':
            show_collaborative_clothes()
            user_id = input('Enter the user_id of a specific user whose ' + \
                             'available clothes you would like to see: ')
            show_user_in_collab(user_id)
        elif action == 'b':
            store_name = input('Enter a store name: ')
            show_store_inventory(store_name)
            filter = input('Would you like to filter by price (p), clothing '\
                            + 'type (t), or discount (d)? ')
            if filter == 'p':
                min_price = input('Minimum price (in USD): $')
                max_price = input('Maximum price (in USD): $')
                filter_store_by_price(store_name, min_price, max_price)
            elif filter == 't':
                clothing_type = input('Clothing type: ')
                filter_store_by_type(store_name, clothing_type)
            elif filter == 'd':
                min_discount = input('Minimum discount (%): ')
                max_discount = input('Maximum disocunt (%): ')
                filter_store_by_discount(store_name, min_discount, max_discount)
        elif action == 'c':
            create_outfit()
        else:
            quit_ui()

def show_client_options(username):
    """
    Prints out different options for restricted users (those that have not
    defined a role for themselves) and allows them to see collaborative 
    closet items or quit the program. 
    """
    # restricted for users without a role 
    print('Client options: ')
    print('  (a) show collaborative clothes')
    print('  (q) quit')

    while True: 
        action = input('Enter an option: ')[0].lower()
        if action == 'a':
            show_collaborative_clothes()
        else:
            quit_ui()

def quit_ui():
    """
    Quits the program, printing a good bye message to the user.
    """
    print('Good bye!')
    conn.close()
    exit()

def main():
    """
    Main function for starting things up.
    """
    username = login()
    show_options(username)

if __name__ == '__main__':
    conn = get_conn('appadmin', 'adminpw')
    main()
