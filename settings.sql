-- USEFUL SETTINGS
show wrap;
set linesize 5000;
alter session set nls_language = 'English';
-- 
SELECT table_name FROM all_tables WHERE owner = 'FSDB235';
SELECT * FROM all_tables WHERE owner = 'FSDB235';
SELECT * FROM REFERENCES;




-- 

-- TABLE_NAME
-- --------------------------------------------------------------------------------------------------------------------------------
-- ANONYPOSTS
-- BILLING_DATA
-- CATALOGUE
-- CLIENTS
-- CLIENT_ADDRESSES
-- CLIENT_CARDS

-- ORDERS_CLIENTS
SELECT * FROM ORDERS_CLIENTS;
DESC ORDERS_CLIENTS;

-- CLIENT_LINES
SELECT * FROM CLIENT_LINES;
DESC CLIENT_LINES;

SELECT DISTINCT barcode FROM CLIENT_LINES;
-- 751 rows selected

SELECT DISTINCT country FROM CLIENT_LINES;
-- 244 rows selected


-- ORDERS_ANONYM
SELECT * FROM ORDERS_ANONYM;
DESC ORDERS_ANONYM;

-- LINES_ANONYM
SELECT * FROM LINES_ANONYM;
DESC LINES_ANONYM;

SELECT DISTINCT barcode FROM LINES_ANONYM;
-- 738 rows selected

SELECT DISTINCT dliv_country FROM LINES_ANONYM;
-- 147 rows selected



-- CREDIT_CARD_DATA
-- CUSTOMERS
-- CUSTOMER_COMMENTS
-- DELIVERY

-- TABLE_NAME
-- --------------------------------------------------------------------------------------------------------------------------------


-- MARKETING_FORMAT
-- NON_REGISTERED
-- ORDERS_ITEM
-- ORIGINS
-- POSTS

-- PRODUCTS
SELECT * FROM products;
DESC products;


SELECT distinct varietal FROM Products;
-- 66 rows selected
SELECT distinct origin FROM Products; 
-- 33 rows selected
SELECT distinct product FROM Products; 
-- 752 rows selected
SELECT distinct origin FROM Products; 
-- 33 rows selected

-- PROVIDERS
-- PURCHASE_ORDER

-- TABLE_NAME
-- --------------------------------------------------------------------------------------------------------------------------------
-- P_REFERENCE
-- REFERENCES
-- REGISTERED
-- REPLACEMENTS
-- REPLACEMENT_ORDER
-- SUPPLIER
-- SUPPLY_LINES
SELECT * FROM SUPPLY_LINES;

-- VARIETALS