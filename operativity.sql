CREATE OR REPLACE PACKAGE caffeine AS

  -- Procedure to set replacement orders from draft to placed
  PROCEDURE Set_Replacement_Orders;

  -- Procedure to report on a provider
  PROCEDURE Report_On_Provider(cif VARCHAR2);

END caffeine;
/

CREATE OR REPLACE PACKAGE BODY caffeine AS

  -- Procedure to set replacement orders from draft to placed
  PROCEDURE Set_Replacement_Orders IS
  BEGIN
    UPDATE Replacements
    SET status = 'P'  -- Assuming 'P' stands for 'placed'
    WHERE status = 'D';  -- Assuming 'D' stands for 'draft'
  END Set_Replacement_Orders;

  -- Procedure to report on a provider
  PROCEDURE Report_On_Provider(cif VARCHAR2) IS
    v_num_orders_placed INT;
    v_num_orders_fulfilled INT;
    v_avg_delivery_period NUMERIC;
  BEGIN
    -- Calculate the number of placed and fulfilled orders
    SELECT COUNT(*)
    INTO v_num_orders_placed
    FROM Replacements
    WHERE taxID = cif AND status = 'P';

    SELECT COUNT(*)
    INTO v_num_orders_fulfilled
    FROM Replacements
    WHERE taxID = cif AND status = 'F';  -- Assuming 'F' stands for 'fulfilled'

    -- Calculate the average delivery period
    SELECT AVG(deldate - orderdate)
    INTO v_avg_delivery_period
    FROM Replacements
    WHERE taxID = cif AND status = 'F';

    -- Output the results
    DBMS_OUTPUT.PUT_LINE('Number of orders placed: ' || v_num_orders_placed);
    DBMS_OUTPUT.PUT_LINE('Number of orders fulfilled: ' || v_num_orders_fulfilled);
    DBMS_OUTPUT.PUT_LINE('Average delivery period: ' || v_avg_delivery_period || ' days');

    -- Add more code here to generate the detailed report for each reference
  END Report_On_Provider;

END caffeine;
/
