-- -----------------------------------
-- - SCRIPTS DE INSERCIÓN DE DATOS -
-- -----------------------------------

INSERT INTO Varietals(name)  (SELECT DISTINCT rtrim(varietal) FROM FSDB.catalogue);
-- 66 rows created.
INSERT INTO Origins(name) (SELECT DISTINCT rtrim(origin) FROM FSDB.catalogue);
-- 33 rows created.

INSERT INTO Products (product, coffea, varietal, origin, roast, decaf)
 (SELECT DISTINCT rtrim(product), substr(coffea,1,1), rtrim(varietal), rtrim(origin), 
                  upper(substr(roasting,1,1)), upper(substr(decaf,1,1)) 
     FROM FSDB.catalogue
 );
-- 750 rows created.

INSERT INTO Products (product, coffea, varietal, origin, roast, decaf)
 (SELECT DISTINCT rtrim(product), substr(coffea,1,1), rtrim(varietal), rtrim(origin), 
                  upper(substr(roasting,1,1)), CASE substr(dcafprocess,1,1) WHEN '-' then 'N' else 'Y' end 
     FROM FSDB.trolley where rtrim(product) not in (select product from products)
 );
-- 2 rows created.
-- notice for these there will be no supply line by now


INSERT INTO References (barCode, product, format, pack_type, pack_unit, quantity, 
                        price, cur_stock, min_stock, max_stock)
 (SELECT DISTINCT barCode, trim(product), case format when 'raw bean' then 'B' else upper(substr(format,1,1)) end,
                  substr(packaging,1,instr(packaging,' ')-1), substr(packaging,instr(packaging,' ',1,2)+1),
                  to_number(substr(substr(packaging,1,instr(packaging,' ',1,2)-1),instr(packaging,' ')+1)), 
                  to_number(substr(retail_price,1,instr(retail_price,' ')-1),'9999.99'), 
                  to_number(cur_stock), to_number(min_stock), to_number(max_stock) 
     FROM FSDB.catalogue 
     WHERE rtrim(barCode) is not null
 );
-- 3240 rows created.

INSERT INTO References (barCode, product, format, pack_type, pack_unit, quantity,price)
 (SELECT DISTINCT barCode, trim(product), case prodtype when 'raw bean' then 'B' else upper(substr(prodtype,1,1)) end,
                  substr(packaging,1,instr(packaging,' ')-1), substr(packaging,instr(packaging,' ',1,2)+1),
                  to_number(substr(substr(packaging,1,instr(packaging,' ',1,2)-1),instr(packaging,' ')+1)), 
                  to_number(substr(base_price,1,instr(base_price,' ')-1),'9999.99')
     FROM FSDB.trolley 
     WHERE rtrim(barCode) is not null AND rtrim(barcode) not in (select barcode from references)
 );
-- 1 rows created.
-- notice for this one there will be no supply line by now


INSERT INTO Providers (taxID, name, person, email, mobile, bankAcc, address, country)
 (SELECT DISTINCT rtrim(prov_taxID), rtrim(supplier), rtrim(prov_person), rtrim(prov_email), to_number(prov_mobile), 
                  rtrim(prov_bankAcc), rtrim(prov_address), rtrim(prov_country)
     FROM FSDB.catalogue 
     WHERE prov_taxid is not null
 );
-- 249 rows created.
-- first problem (primary key violation; document)
-- 1 row skipped. 


INSERT INTO Supply_Lines (taxID, barCode, cost)
 (SELECT p,b,min(c) FROM
   (SELECT DISTINCT rtrim(prov_taxID) p, barCode b, to_number(substr(cost_price,1,instr(cost_price,' ')-1),'9999.99') c
       FROM FSDB.catalogue
       WHERE prov_taxid is not null AND rtrim(barCode) is not null
   ) GROUP BY p,b
 );
-- 6468 rows created.
-- 1 null row skipped. -- first problem (same row; document)
-- second problem (primary key violation; several costs for the same supplier&barcode; document)
-- 5 repeated supply_lines; heal data: kept minimum cost (implicit semantic assumption)


-- INSERT INTO Replacements (taxID, barCode, orderdate, status, units, deldate, payment)
-- no data


INSERT INTO Clients (username, reg_datetime, user_passw, name, surn1, surn2, email, mobile)
 (SELECT DISTINCT rtrim(username), to_date(reg_date||reg_time,'yyyy / mm / ddhh:mi:ss am'), rtrim(user_passw),
                  rtrim(client_name), rtrim(client_surn1), rtrim(client_surn2), rtrim(client_email), to_number(client_mobile)
     FROM FSDB.trolley
     WHERE username is not null AND client_email is not null
);
-- 688 rows created.

INSERT INTO Clients (username, reg_datetime, user_passw, name, surn1, surn2, mobile, preference)
 (SELECT DISTINCT rtrim(username), to_date(reg_date||reg_time,'yyyy / mm / ddhh:mi:ss am'), rtrim(user_passw),
                  rtrim(client_name), rtrim(client_surn1), rtrim(client_surn2), to_number(client_mobile), 'SMS'
     FROM FSDB.trolley
     WHERE username is not null AND client_email is null 
);
-- implicit assumption: when email is null, default preference is SMS
-- 80 rows created.


INSERT INTO Posts (username, postdate, barCode, product, score, title, text, likes)
 -- null means it isn't endorsed; else, date of last purchase	
 (SELECT DISTINCT rtrim(username), to_date(post_date||post_time,'yyyy / mm / ddhh:mi:ss am'), 
         rtrim(barCode), rtrim(product), to_number(score), rtrim(title), rtrim(text), to_number(likes) 
     FROM FSDB.posts
     WHERE rtrim(product) IN (SELECT distinct product FROM references)
);
-- no post is endorsed yet
-- third problem: one product (and all its references) missing; 
-- solution: skip them (27 rows skipped); document the product
-- 3429 rows created.

-- INSERT INTO AnonyPosts (postdate, barCode, product, score, title, text, likes, endorsed) 
-- no data


INSERT INTO Orders_Anonym (orderdate, contact, contact2, dliv_datetime, name, surn1, surn2, bill_waytype,
                           bill_wayname, bill_gate, bill_block, bill_stairw, bill_floor, bill_door, bill_ZIP, 
                           bill_town, bill_country, dliv_waytype, dliv_wayname, dliv_gate, dliv_block, 
                           dliv_stairw, dliv_floor, dliv_door, dliv_ZIP, dliv_town, dliv_country)
 (SELECT DISTINCT to_date(orderdate||ordertime,'yyyy / mm / ddhh:mi:ss am'), 
                  nvl(rtrim(client_email),rtrim(client_mobile)), nvl2(rtrim(client_email),rtrim(client_mobile),null),
                  to_date(dliv_date||dliv_time,'yyyy / mm / ddhh:mi:ss am'), 
                  rtrim(client_name), rtrim(client_surn1), rtrim(client_surn2), 
                  rtrim(bill_waytype), rtrim(bill_wayname), rtrim(bill_gate), rtrim(bill_block), rtrim(bill_stairw), 
                  rtrim(bill_floor), rtrim(bill_door), rtrim(bill_ZIP), rtrim(bill_town), rtrim(bill_country),
                  rtrim(dliv_waytype), rtrim(dliv_wayname), rtrim(dliv_gate), rtrim(dliv_block), rtrim(dliv_stairw), 
                  rtrim(dliv_floor), rtrim(dliv_door), rtrim(dliv_ZIP), rtrim(dliv_town), rtrim(dliv_country)
 FROM FSDB.trolley
 WHERE rtrim(username) IS NULL
);
-- either email or mobile if email is null
-- mobile (null, unless both email and mobile )
-- 3207 rows created.


INSERT INTO Lines_Anonym (orderdate, contact, dliv_town, dliv_country, barcode, price, quantity, 
                           pay_type, pay_datetime, card_comp, card_num, card_holder, card_expir)
 (SELECT DISTINCT to_date(orderdate||ordertime,'yyyy / mm / ddhh:mi:ss am'), 
                  nvl(rtrim(client_email),rtrim(client_mobile)), rtrim(dliv_town), rtrim(dliv_country), rtrim(barcode), 
                  to_number(substr(base_price,1,instr(base_price,' ')-1),'9999.99'), to_number(quantity),
                  rtrim(payment_type), to_date(payment_date||payment_time,'yyyy / mm / ddhh:mi:ss am'),
                  rtrim(card_company), to_number(card_number), rtrim(card_holder), to_date(card_expiratn,'mm/yy')
     FROM FSDB.trolley
     WHERE rtrim(username) IS NULL
);
-- 3537 rows created.


INSERT INTO Client_Addresses (username, waytype, wayname, gate, block, stairw, floor, door, ZIP, town, country)
 (SELECT DISTINCT rtrim(username), rtrim(bill_waytype), rtrim(bill_wayname), rtrim(bill_gate), 
                  rtrim(bill_block), rtrim(bill_stairw), rtrim(bill_floor), rtrim(bill_door), 
                  rtrim(bill_ZIP), rtrim(bill_town), rtrim(bill_country)
     FROM FSDB.trolley 
     WHERE rtrim(username) is not null
);
-- 768 rows created.

INSERT INTO Client_Addresses (username, waytype, wayname, gate, block, stairw, floor, door, ZIP, town, country)
 (SELECT DISTINCT rtrim(username), rtrim(dliv_waytype), rtrim(dliv_wayname), rtrim(dliv_gate), 
                  rtrim(dliv_block), rtrim(dliv_stairw), rtrim(dliv_floor), rtrim(dliv_door), 
                  rtrim(dliv_ZIP), rtrim(dliv_town), rtrim(dliv_country)
     FROM FSDB.trolley 
     WHERE rtrim(username) is not null AND 
           (rtrim(username),rtrim(dliv_town), rtrim(dliv_country)) NOT IN (SELECT username,town,country from Client_Addresses)
);
-- 1222 rows created.


INSERT INTO Client_Cards (cardnum, username, card_comp, card_holder, card_expir)
 (SELECT DISTINCT to_number(card_number), rtrim(username), rtrim(card_company), rtrim(card_holder), 
                  to_date(card_expiratn,'mm/yy')
 FROM FSDB.trolley
    WHERE rtrim(username) is not null AND to_number(card_number) IS NOT NULL
);
-- 472 rows created.


INSERT INTO Orders_Clients (orderdate, username, town, country, dliv_datetime, bill_town, bill_country) 
 (SELECT DISTINCT to_date(orderdate||ordertime,'yyyy / mm / ddhh:mi:ss am'), 
                  rtrim(username), rtrim(dliv_town), rtrim(dliv_country), 
                  to_date(dliv_date||dliv_time,'yyyy / mm / ddhh:mi:ss am'), 
                  rtrim(bill_town), rtrim(bill_country)
    FROM FSDB.trolley
    WHERE rtrim(username) IS NOT NULL
);
-- 50140 rows created.

INSERT INTO Client_Lines (orderdate, username, town, country, barcode, cardnum, price, quantity, pay_type, pay_datetime)
 (SELECT DISTINCT to_date(orderdate||ordertime,'yyyy / mm / ddhh:mi:ss am'), 
                  rtrim(username), rtrim(dliv_town), rtrim(dliv_country), barcode, to_number(card_number), 
                  to_number(substr(base_price,1,instr(base_price,' ')-1),'9999.99'), to_number(quantity),
                  rtrim(payment_type), to_date(payment_date||payment_time,'yyyy / mm / ddhh:mi:ss am')
    FROM FSDB.trolley
    WHERE rtrim(username) IS NOT NULL
);
-- 55206 rows created.



