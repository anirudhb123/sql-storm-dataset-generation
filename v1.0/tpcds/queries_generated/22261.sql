
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        COUNT(DISTINCT ws_order_number) AS unique_sales
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
    GROUP BY 
        ws_item_sk
),
HighReturnItems AS (
    SELECT 
        ir.i_item_id,
        ir.i_current_price,
        cr.total_returned_quantity,
        cr.unique_returns,
        (COALESCE(cr.total_returned_quantity, 0) * ir.i_current_price) AS total_return_value
    FROM 
        ItemSales ir
    LEFT JOIN 
        CustomerReturns cr ON ir.ws_item_sk = cr.sr_customer_sk
    WHERE 
        cr.total_returned_quantity IS NOT NULL
    HAVING 
        (coalesce(total_returned_quantity, 0) / NULLIF(ir.total_sales_quantity, 0)) > 0.5
)
SELECT
    hi.i_item_id,
    hi.i_current_price,
    hi.total_return_quantity,
    hi.unique_returns,
    hi.total_return_value,
    DENSE_RANK() OVER (ORDER BY hi.total_return_value DESC) AS rank
FROM 
    HighReturnItems hi
JOIN 
    date_dim dd ON dd.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date >= CURRENT_DATE - INTERVAL '1 year')
WHERE 
    hi.total_return_value IS NOT NULL
ORDER BY 
    rank
LIMIT 10;

WITH RECURSIVE RecursiveCustomers AS (
    SELECT c_customer_id, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, r.level + 1
    FROM customer c
    INNER JOIN RecursiveCustomers r ON c.c_current_cdemo_sk = r.c_current_cdemo_sk
    WHERE r.level < 5
)
SELECT
    COUNT(DISTINCT rc.c_customer_id) AS total_related_customers,
    MAX(rc.level) AS max_relationship_depth
FROM
    RecursiveCustomers rc
WHERE
    rc.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = 'F');
