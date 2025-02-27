
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_returned_amount,
        COUNT(DISTINCT cr_order_number) AS total_return_count
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
CustomerSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnRate AS (
    SELECT 
        cs.customer_sk,
        COALESCE(cr.total_returned_quantity, 0) AS returned_quantity,
        COALESCE(cs.total_quantity_sold, 0) AS sold_quantity,
        CASE 
            WHEN COALESCE(cs.total_quantity_sold, 0) > 0 THEN 
                COALESCE(cr.total_returned_quantity, 0) / COALESCE(cs.total_quantity_sold, 0)
            ELSE 
                NULL 
        END AS return_rate
    FROM CustomerSales cs
    LEFT JOIN CustomerReturns cr ON cs.customer_sk = cr.cr_returning_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(rr.return_rate, 0) AS return_rate,
    c.c_first_name,
    c.c_last_name,
    d.d_date,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY rr.return_rate DESC) as return_rank
FROM customer c
LEFT JOIN ReturnRate rr ON c.c_customer_sk = rr.customer_sk
JOIN date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 1)
WHERE rr.return_rate IS NOT NULL
ORDER BY rr.return_rate DESC
FETCH FIRST 10 ROWS ONLY;
