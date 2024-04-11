
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
        -- %TYPE to ensure they have the same data types
        v_name Providers.name%TYPE;
        v_address Providers.address%TYPE;
        v_country Providers.country%TYPE;
        total_orders NUMBER;
        total_fulfilled NUMBER;
        avg_delivery_period NUMBER; -- Placeholder, assuming we calculate it elsewhere
        min_cost NUMBER;
        max_cost NUMBER;
        avg_cost_diff NUMBER;
        current_cost NUMBER;
    BEGIN
        SELECT name, address, country
        INTO v_name, v_address, v_country
        FROM Providers
        WHERE taxID = provider_taxID;

        DBMS_OUTPUT.PUT_LINE('Provider Name: ' || v_name);
        DBMS_OUTPUT.PUT_LINE('Address: ' || v_address);
        DBMS_OUTPUT.PUT_LINE('Country: ' || v_country);

        -- Get total and fulfilled orders count, and average delivery period
        SELECT COUNT(*), COUNT(CASE WHEN status = 'F' THEN 1 END), AVG(deldate - orderdate)
        INTO total_orders, total_fulfilled, avg_delivery_period
        FROM Replacements
        WHERE taxID = provider_taxID AND orderdate >= ADD_MONTHS(SYSDATE, -12) AND status IN ('F', 'P');

        DBMS_OUTPUT.PUT_LINE('Total Orders Placed in Last Year: ' || total_orders);
        DBMS_OUTPUT.PUT_LINE('Total Orders Fulfilled in Last Year: ' || total_fulfilled);
        DBMS_OUTPUT.PUT_LINE('Average Delivery Period for Fulfilled Orders: ' || avg_delivery_period || ' days');

        -- Loop through each product supplied by the provider and display details
        FOR rec IN (
            SELECT p.product, r.barCode, sl.cost AS current_cost
            FROM Products p
            JOIN References r ON p.product = r.product
            JOIN Supply_Lines sl ON r.barCode = sl.barCode
            WHERE sl.taxID = provider_taxID
        ) LOOP
            -- Get the minimum, maximum, and current cost for each product reference
            SELECT MIN(cost), MAX(cost), rec.current_cost
            INTO min_cost, max_cost, current_cost
            FROM Supply_Lines
            WHERE barCode = rec.barCode;

            -- Calculate average cost difference
            SELECT AVG(abs(cost - current_cost)) INTO avg_cost_diff
            FROM Supply_Lines
            WHERE barCode = rec.barCode;

            DBMS_OUTPUT.PUT_LINE('Product: ' || rec.product || ', Barcode: ' || rec.barCode ||
                                 ', Current Cost: ' || current_cost || ', Min Cost: ' || min_cost ||
                                 ', Max Cost: ' || max_cost || ', Avg Cost Diff: ' || avg_cost_diff);
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

-- M31514871H
-- F28409113L
-- there are no time data in supply_lines so I assume that
-- I get it from Replacements, but there is not enough data
-- the min_cost and max_cost 

BEGIN
    caffeine.ReportOnProvider('M31514871H');
END;
/

SELECT sl.taxID, p.name, sl.cost
FROM Supply_Lines sl
JOIN Providers p ON sl.taxID = p.taxID
WHERE sl.barCode = 'QOO68235O807729';
