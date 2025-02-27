
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_tax) AS total_return_tax
    FROM store_returns
    GROUP BY sr_customer_sk
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_ext_sales_price) AS total_sales_value,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    GROUP BY ws_item_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.sr_customer_sk, 
        cr.total_returns, 
        cr.total_return_amount,
        RANK() OVER (ORDER BY cr.total_return_amount DESC) AS rank
    FROM CustomerReturns cr
    WHERE cr.total_returns > 0
)
SELECT 
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    cu.c_email_address,
    COALESCE(hrc.total_returns, 0) AS return_count,
    COALESCE(hrc.total_return_amount, 0) AS total_return_value,
    COALESCE(its.total_sold_quantity, 0) AS total_quantity_sold,
    COALESCE(its.total_sales_value, 0) AS total_sales_value
FROM customer cu
LEFT JOIN HighReturnCustomers hrc ON cu.c_customer_sk = hrc.sr_customer_sk
LEFT JOIN ItemSales its ON its.ws_item_sk IN (
    SELECT sr_item_sk 
    FROM store_returns sr 
    WHERE sr_customer_sk = cu.c_customer_sk
)
WHERE cu.c_birth_year IS NOT NULL
    AND (cu.c_preferred_cust_flag = 'Y' OR hrc.total_returns > 1)
ORDER BY total_return_value DESC, return_count DESC
LIMIT 100;
