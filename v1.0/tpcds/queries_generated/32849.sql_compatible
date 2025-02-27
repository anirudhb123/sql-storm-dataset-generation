
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 0 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON ch.c_customer_sk = c.c_current_addr_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        d.d_year,
        d.d_month_seq,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(sr_ticket_number) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    d.d_month_seq,
    SUM(sd.ws_ext_sales_price) AS total_sales,
    COALESCE(cr.total_return_amt, 0) AS total_returns,
    COUNT(DISTINCT CASE WHEN sd.sales_rank = 1 THEN sd.ws_order_number END) AS total_high_value_orders
FROM CustomerHierarchy ch
LEFT JOIN SalesData sd ON ch.c_customer_sk = sd.ws_item_sk
LEFT JOIN CustomerReturns cr ON ch.c_customer_sk = cr.sr_customer_sk
JOIN date_dim d ON d.d_year = 2023
GROUP BY ch.c_first_name, ch.c_last_name, d.d_month_seq
HAVING SUM(sd.ws_ext_sales_price) > 1000
ORDER BY d.d_month_seq, total_sales DESC;
