-- 2.1 Trigger for Moving Purchases

CREATE OR REPLACE TRIGGER MovePurchasesToAnon
AFTER DELETE ON Clients
FOR EACH ROW
BEGIN
    -- Inserting into Orders_Anonym from Orders_Clients
    INSERT INTO Orders_Anonym (
        orderdate,
        contact,
        contact2,
        dliv_datetime,
        name,
        surn1,
        -- surn2,
        -- bill_waytype,
        -- bill_wayname,
        -- bill_gate,
        -- bill_block,
        -- bill_stairw,
        -- bill_floor,
        -- bill_door,
        -- bill_ZIP,
        bill_town,
        bill_country,
        dliv_waytype,
        dliv_wayname,
        dliv_gate,
        dliv_block,
        dliv_stairw,
        dliv_floor,
        dliv_door,
        dliv_ZIP,
        dliv_town,
        dliv_country
    )
    SELECT
        oc.orderdate,
        COALESCE(oc.email, oc.mobile) AS contact,
        oc.mobile AS contact2,
        oc.dliv_datetime,
        oc.username,
        -- oc.surn1,
        -- oc.surn2,
        -- oc.bill_waytype,
        -- oc.bill_wayname,
        -- oc.bill_gate,
        -- oc.bill_block,
        -- oc.bill_stairw,
        -- oc.bill_floor,
        -- oc.bill_door,
        -- oc.bill_ZIP,
        oc.bill_town,
        oc.bill_country,
        ca.waytype AS dliv_waytype,
        ca.wayname AS dliv_wayname,
        ca.gate AS dliv_gate,
        ca.block AS dliv_block,
        ca.stairw AS dliv_stairw,
        ca.floor AS dliv_floor,
        ca.door AS dliv_door,
        ca.ZIP AS dliv_ZIP,
        ca.town AS dliv_town,
        ca.country AS dliv_country
    FROM Orders_Clients oc
    LEFT JOIN Client_Addresses ca ON oc.username = ca.username
    WHERE oc.username = :OLD.username;

    -- Delete the orders from Orders_Clients
    DELETE FROM Orders_Clients WHERE username = :OLD.username;
END;
/



SHOW ERRORS TRIGGER MovePurchasesToAnon;

-- 2.2 Trigger for Moving Posts

CREATE OR REPLACE TRIGGER MovePostsToAnon
AFTER DELETE ON Clients
FOR EACH ROW
BEGIN
    INSERT INTO AnonyPosts(postdate, barCode, product, score, title, text, likes, endorsed)
    SELECT postdate, barCode, product, score, title, text, likes, endorsed
    FROM Posts
    WHERE username = :OLD.username;

    DELETE FROM Posts WHERE username = :OLD.username;
END;
/
