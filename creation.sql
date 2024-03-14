-- -----------------------------------
-- - SCRIPTS DE CREACIÓN E INSERCIÓN -
-- -----------------------------------

-- - TABLES DESTRUCTION  - - - - - - -
-- -----------------------------------

DROP TABLE Client_Lines CASCADE CONSTRAINTS;
DROP TABLE Orders_Clients CASCADE CONSTRAINTS;
DROP TABLE Client_Cards CASCADE CONSTRAINTS;
DROP TABLE Client_Addresses CASCADE CONSTRAINTS;
DROP TABLE Lines_Anonym CASCADE CONSTRAINTS;
DROP TABLE Orders_Anonym CASCADE CONSTRAINTS;
DROP TABLE AnonyPosts  CASCADE CONSTRAINTS;
DROP TABLE Posts  CASCADE CONSTRAINTS;
DROP TABLE Clients CASCADE CONSTRAINTS;
DROP TABLE Replacements CASCADE CONSTRAINTS;
DROP TABLE Supply_lines CASCADE CONSTRAINTS;
DROP TABLE Providers CASCADE CONSTRAINTS;
DROP TABLE References  CASCADE CONSTRAINTS;
DROP TABLE Products CASCADE CONSTRAINTS;
DROP TABLE Origins CASCADE CONSTRAINTS;
DROP TABLE Varietals CASCADE CONSTRAINTS;



-- - VALIDATION TABLES - - - - - - - -
-- -----------------------------------
CREATE TABLE Varietals (
  name      VARCHAR2(30),
  CONSTRAINT pk_varietal PRIMARY KEY(name) 
);
CREATE TABLE Origins (
  name      VARCHAR2(30),
  CONSTRAINT pk_origins PRIMARY KEY(name) 
);


-- - TABLES CREATION - - - - - - - - -
-- -----------------------------------

CREATE TABLE Products (
  product      VARCHAR2(50),
  coffea       CHAR(1) NOT NULL,
  varietal     VARCHAR2(30) NOT NULL,
  origin       VARCHAR2(15) NOT NULL,
  roast        CHAR(1) NOT NULL,
  decaf        CHAR(1) NOT NULL,
  CONSTRAINT pk_products PRIMARY KEY(product), 
  CONSTRAINT fk_products_varietals FOREIGN KEY(varietal) REFERENCES Varietals,
  CONSTRAINT fk_products_origins FOREIGN KEY(origin) REFERENCES Origins,
  CONSTRAINT D_coffea CHECK (coffea IN ('A','C','L')), 
  CONSTRAINT D_roast CHECK (roast IN ('N','H','B')), 
  CONSTRAINT D_decaf CHECK (decaf IN ('Y','N')) 
);


CREATE TABLE References (
  barCode      CHAR(15),
  product      VARCHAR2(50) NOT NULL,
  format       CHAR(1) NOT NULL,
  pack_type    VARCHAR2(10) NOT NULL,
  pack_unit    VARCHAR2(10) NOT NULL,
  quantity     NUMBER(6) NOT NULL,
  price        NUMBER(12,2) NOT NULL,
  cur_stock    NUMBER(5) DEFAULT(0) NOT NULL,
  min_stock    NUMBER(5) DEFAULT(5) NOT NULL,
  max_stock    NUMBER(5) DEFAULT(15) NOT NULL,
  CONSTRAINT pk_references PRIMARY KEY(barcode), 
  CONSTRAINT uk_references UNIQUE (product,barcode), 
  CONSTRAINT fk_references_products FOREIGN KEY(product) 
             REFERENCES Products ON DELETE CASCADE,
  CONSTRAINT D_format CHECK (format IN ('C','G','P','R','B','F'))
);


CREATE TABLE Providers (
  taxID     CHAR(10),
  name      VARCHAR2(35) NOT NULL,
  person    VARCHAR2(90) NOT NULL,
  email     VARCHAR2(60) NOT NULL,
  mobile    NUMBER(9) NOT NULL,
  bankAcc   VARCHAR2(30),
  address   VARCHAR2(120) NOT NULL,
  country   VARCHAR2(45) NOT NULL,
  CONSTRAINT pk_providers PRIMARY KEY(taxID) 
);


CREATE TABLE Supply_Lines (
  taxID     CHAR(10),
  barCode   CHAR(15),
  cost      NUMBER(10,2) NOT NULL,
  CONSTRAINT pk_supply PRIMARY KEY(taxID,barcode), 
  CONSTRAINT fk_supply_references FOREIGN KEY(barcode) 
             REFERENCES References ON DELETE CASCADE,
  CONSTRAINT fk_supply_providers FOREIGN KEY(taxID) 
             REFERENCES providers ON DELETE CASCADE
);


CREATE TABLE Replacements (
  taxID     CHAR(10),
  barCode   CHAR(15),
  orderdate DATE,
  status    CHAR(1) DEFAULT ('D') NOT NULL,
  units     NUMBER(5) NOT NULL,
  deldate   DATE,
  payment   NUMBER(12,2) NOT NULL,
  CONSTRAINT pk_replacements PRIMARY KEY(taxID,barcode,orderdate), 
  CONSTRAINT fk_replacements_supply FOREIGN KEY(taxID,barcode) REFERENCES Supply_Lines,
  CONSTRAINT D_status CHECK (status IN ('D','P','F'))
);


CREATE TABLE Clients (
  username      VARCHAR2(30),
  reg_datetime  DATE NOT NULL,
  user_passw    VARCHAR2(15) NOT NULL,
  name          VARCHAR2(35) NOT NULL,
  surn1         VARCHAR2(30) NOT NULL,
  surn2         VARCHAR2(30),
  email         VARCHAR2(60),
  mobile        NUMBER(9),
  preference    VARCHAR2(12) DEFAULT('EMAIL') NOT NULL,
  voucher       NUMBER(2) DEFAULT (0) NOT NULL,
  voucher_exp   DATE,
  CONSTRAINT pk_ PRIMARY KEY(username),
  CONSTRAINT ck_client CHECK (email is not null or mobile is not null) 
);


CREATE TABLE Posts (
  username   VARCHAR2(30),
  postdate   DATE,
  barCode    CHAR(15),
  product    VARCHAR2(50) NOT NULL,
  score      NUMBER(1) NOT NULL, 
  title      VARCHAR2(50),
  text       VARCHAR2(2000) NOT NULL, 
  likes      NUMBER(9) DEFAULT(0) NOT NULL, 
  endorsed   DATE, -- null means it isn't endorsed; else, date of last purchase	
  CONSTRAINT pk_posts PRIMARY KEY(username,postdate),
  CONSTRAINT fk_posts_clients FOREIGN KEY(username) REFERENCES Clients,
  CONSTRAINT fk_posts_references FOREIGN KEY(product,barcode) 
             REFERENCES References(product,barcode),
  CONSTRAINT D_postscore CHECK (score between 0 and 5)
);

CREATE TABLE AnonyPosts (
  postdate   DATE,
  barCode    CHAR(15),
  product    VARCHAR2(50) NOT NULL,
  score      NUMBER(1) NOT NULL, 
  title      VARCHAR2(50),
  text       VARCHAR2(2000) NOT NULL, 
  likes      NUMBER(9) DEFAULT(0) NOT NULL, 
  endorsed   DATE, -- null means it isn't endorsed; else, date of last purchase	
  CONSTRAINT pk_anonyposts PRIMARY KEY(postdate),
  CONSTRAINT fk_anonyposts_references FOREIGN KEY(product,barcode) 
             REFERENCES References(product,barcode), 
  CONSTRAINT D_anonyscore CHECK (score between 0 and 5)
);


CREATE TABLE Orders_Anonym (
  orderdate     DATE,
  contact       VARCHAR2(60),  -- either email or mobile if email is null
  contact2      NUMBER(9),     -- mobile (null, unless both email and mobile not null)
  dliv_datetime DATE,
  name          VARCHAR2(35) NOT NULL,
  surn1         VARCHAR2(30) NOT NULL,
  surn2         VARCHAR2(30),
  bill_waytype  CHAR(10) NOT NULL,
  bill_wayname  CHAR(30) NOT NULL,
  bill_gate     CHAR(3),
  bill_block    CHAR(1),
  bill_stairw   CHAR(2),
  bill_floor    CHAR(7),
  bill_door     CHAR(1),
  bill_ZIP      CHAR(5) NOT NULL,
  bill_town     CHAR(45) NOT NULL,
  bill_country  CHAR(45) NOT NULL,
  dliv_waytype  CHAR(10) NOT NULL,
  dliv_wayname  CHAR(30) NOT NULL,
  dliv_gate     CHAR(3),
  dliv_block    CHAR(1),
  dliv_stairw   CHAR(2),
  dliv_floor    CHAR(7),
  dliv_door     CHAR(2),
  dliv_ZIP      CHAR(5) NOT NULL,
  dliv_town     CHAR(45),
  dliv_country  CHAR(45),
  CONSTRAINT pk_anonyorders PRIMARY KEY(orderdate,contact,dliv_town,dliv_country)
);

CREATE TABLE Lines_Anonym (
  orderdate     DATE,
  contact       VARCHAR2(60),
  dliv_town     CHAR(45),
  dliv_country  CHAR(45),
  barcode       CHAR(15),
  price         NUMBER(12,2) NOT NULL,
  quantity      NUMBER(2) NOT NULL,
  pay_type      VARCHAR2(15) NOT NULL,
  pay_datetime  DATE,
  card_comp     VARCHAR2(15),
  card_num      NUMBER(20),
  card_holder   VARCHAR2(30),
  card_expir    DATE,
  CONSTRAINT pk_anonylines PRIMARY KEY(orderdate,contact,dliv_town,dliv_country,barcode),
  CONSTRAINT fk_anonylines_anonyorders FOREIGN KEY(orderdate,contact,dliv_town,dliv_country) 
             REFERENCES Orders_Anonym ON DELETE CASCADE, 
  CONSTRAINT fk_anonylines_references FOREIGN KEY(barcode) REFERENCES References,
  CONSTRAINT D_anonycards CHECK (UPPER(pay_type)!='CREDIT CARD' OR  
                                 (card_comp IS NOT NULL AND card_num IS NOT NULL AND 
                                  card_holder IS NOT NULL AND card_expir IS NOT NULL))
);


CREATE TABLE Client_Addresses (
  username VARCHAR2(30),
  waytype  VARCHAR2(10) NOT NULL,
  wayname  VARCHAR2(30) NOT NULL,
  gate     VARCHAR2(3),
  block    VARCHAR2(1),
  stairw   VARCHAR2(2),
  floor    VARCHAR2(7),
  door     VARCHAR2(2),
  ZIP      VARCHAR2(5) NOT NULL,
  town     VARCHAR2(45),
  country  VARCHAR2(45),
  CONSTRAINT pk_address PRIMARY KEY(username,town,country),
  CONSTRAINT fk_addresses_clients FOREIGN KEY(username) 
             REFERENCES Clients ON DELETE CASCADE
);


CREATE TABLE Client_Cards (
  cardnum      NUMBER(20),
  username      VARCHAR2(30) NOT NULL,
  card_comp     VARCHAR2(15) NOT NULL,
  card_holder   VARCHAR2(30) NOT NULL,
  card_expir    DATE NOT NULL,
  CONSTRAINT pk_cards PRIMARY KEY(cardnum),
  CONSTRAINT fk_cards_clients FOREIGN KEY(username) 
             REFERENCES Clients ON DELETE CASCADE
);


CREATE TABLE Orders_Clients (
  orderdate     DATE,
  username      VARCHAR2(30),
  town          VARCHAR2(45),
  country       VARCHAR2(45),
  dliv_datetime DATE,
  bill_town     VARCHAR2(45) NOT NULL,
  bill_country  VARCHAR2(45) NOT NULL,
  discount      NUMBER(2) default(0), 
  CONSTRAINT pk_clientorders PRIMARY KEY(orderdate,username,town,country),
  CONSTRAINT fk_order_address FOREIGN KEY(username,town,country) REFERENCES Client_Addresses,
  CONSTRAINT fk_order_bill FOREIGN KEY(username,bill_town,bill_country) 
                REFERENCES Client_Addresses
);

CREATE TABLE Client_Lines (
  orderdate     DATE,
  username      VARCHAR2(30),
  town          VARCHAR2(45),
  country       VARCHAR2(45),
  barcode       CHAR(15),
  price         NUMBER(12,2) NOT NULL,
  quantity      VARCHAR2(2) NOT NULL,
  pay_type      VARCHAR2(15) NOT NULL,
  pay_datetime  DATE,
  cardnum       NUMBER(20),
  CONSTRAINT pk_clientlines PRIMARY KEY(orderdate,username,town,country,barcode),
  CONSTRAINT fk_clientlines_anonyorders FOREIGN KEY(orderdate,username,town,country) 
             REFERENCES Orders_Clients ON DELETE CASCADE, 
  CONSTRAINT fk_clientlines_references FOREIGN KEY(barcode) REFERENCES References,
  CONSTRAINT fk_lines_creditcard FOREIGN KEY(cardnum) REFERENCES Client_Cards,
  CONSTRAINT D_clientcards CHECK (UPPER(pay_type)!='CREDIT CARD' OR cardnum IS NOT NULL)
);

select table_name from user_tables;

