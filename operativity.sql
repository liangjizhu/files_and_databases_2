
CREATE OR REPLACE PACKAGE caffeine AS
    -- Procedure to set replacement orders from draft to placed
    PROCEDURE SetReplacementOrders;
    -- Procedure to report on a provider
    PROCEDURE ReportOnProvider(provider_taxID IN CHAR);
END caffeine;
/

CREATE OR REPLACE PACKAGE BODY caffeine AS

    -- Procedure to update the status of replacement orders
    PROCEDURE SetReplacementOrders AS
    BEGIN
        -- Loop through each record where the replacement order is draft ('D')
        -- and current stock is less than minimum stock
        FOR rec IN (SELECT r.barCode, r.min_stock, r.cur_stock, r.max_stock
                    FROM References r
                    JOIN Replacements rep ON r.barCode = rep.barCode
                    WHERE rep.status = 'D' AND r.cur_stock < r.min_stock)
        LOOP
            -- Update the status to 'P' (Placed) for the fetched records
            -- and calculate the units based on max_stock and cur_stock
            UPDATE Replacements
            SET status = 'P',
                units = rec.max_stock - rec.cur_stock,
                orderdate = SYSDATE
            WHERE barCode = rec.barCode
            AND status = 'D';
        END LOOP;
        COMMIT; -- Commit the transaction to save the changes
    END SetReplacementOrders;

    -- Procedure to report on a provider given its tax ID
     PROCEDURE ReportOnProvider(provider_taxID IN CHAR) IS
        v_name Providers.name%TYPE;
        v_address Providers.address%TYPE;
        v_country Providers.country%TYPE;
        total_orders NUMBER;
        total_fulfilled NUMBER;
        avg_delivery_period NUMBER;
        min_cost NUMBER;
        max_cost NUMBER;
        avg_cost NUMBER;
        current_cost_diff NUMBER;
        best_offer_diff NUMBER;
        second_best_cost NUMBER;
    BEGIN
        SELECT name, address, country
        INTO v_name, v_address, v_country
        FROM Providers
        WHERE taxID = provider_taxID;

        DBMS_OUTPUT.PUT_LINE('Provider Name: ' || v_name);
        DBMS_OUTPUT.PUT_LINE('Address: ' || v_address);
        DBMS_OUTPUT.PUT_LINE('Country: ' || v_country);

        SELECT COUNT(*), COUNT(CASE WHEN status = 'F' THEN 1 END)
        INTO total_orders, total_fulfilled
        FROM Replacements
        WHERE taxID = provider_taxID AND orderdate >= ADD_MONTHS(SYSDATE, -12);

        -- Assuming delivery_period needs to be calculated or retrieved correctly
        -- This is a placeholder for the actual delivery period calculation logic
        avg_delivery_period := 0;

        DBMS_OUTPUT.PUT_LINE('Total Orders: ' || total_orders);
        DBMS_OUTPUT.PUT_LINE('Total Fulfilled Orders: ' || total_fulfilled);
        DBMS_OUTPUT.PUT_LINE('Average Delivery Period: ' || avg_delivery_period || ' days');

        FOR rec IN (SELECT p.product, r.barCode, sl.cost AS current_cost
                    FROM Products p
                    JOIN References r ON p.product = r.product
                    JOIN Supply_Lines sl ON r.barCode = sl.barCode
                    WHERE sl.taxID = provider_taxID)
        LOOP
            SELECT MIN(cost), MAX(cost), AVG(cost)
            INTO min_cost, max_cost, avg_cost
            FROM Supply_Lines
            WHERE barCode = rec.barCode
            AND taxID = provider_taxID
            AND EXISTS (SELECT 1 FROM Replacements WHERE barCode = rec.barCode AND orderdate >= ADD_MONTHS(SYSDATE, -12));

            current_cost_diff := rec.current_cost - avg_cost;

            SELECT MIN(cost), NVL(MIN(CASE WHEN cost > rec.current_cost THEN cost END), MIN(cost))
            INTO best_offer_diff, second_best_cost
            FROM Supply_Lines
            WHERE barCode = rec.barCode;

            IF best_offer_diff = rec.current_cost THEN
                best_offer_diff := second_best_cost - rec.current_cost;
            ELSE
                best_offer_diff := best_offer_diff - rec.current_cost;
            END IF;

            DBMS_OUTPUT.PUT_LINE('Product: ' || rec.product || ', Barcode: ' || rec.barCode ||
                                 ', Current Cost: ' || rec.current_cost || ', Min Cost: ' || min_cost ||
                                 ', Max Cost: ' || max_cost || ', Avg Cost Diff: ' || current_cost_diff ||
                                 ', Best Offer Diff: ' || best_offer_diff);
        END LOOP;
    END ReportOnProvider;

END caffeine;
/


-- tests
BEGIN
    caffeine.SetReplacementOrders;
END;
/
-- search a barcode for current stock less that mininum stock
SELECT r.barCode, r.min_stock, r.cur_stock, r.max_stock
FROM References r
WHERE r.cur_stock < r.min_stock;

-- result:
-- BARCODE          MIN_STOCK  CUR_STOCK  MAX_STOCK
--------------- ---------- ---------- ----------
-- Q Q77433Q270983          5          0         15

-- search if there is a provider for this barcode,
-- so we can update replacement table and execute the procedure
SELECT sl.taxID, p.name
FROM Supply_Lines sl
JOIN Providers p ON sl.taxID = p.taxID
WHERE sl.barCode = 'Q Q77433Q270983';

-- result:
-- no rows selected
-- since there is no provider, the status of draft order cannot be updated so
-- it cannot be tested in the given database

BEGIN
    caffeine.ReportOnProvider('M31514871H');
END;
/