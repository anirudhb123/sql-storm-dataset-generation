
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, 
           CAST(0 AS INTEGER) AS level
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, 
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM web_sales ws
    GROUP BY ws.ws_order_number, ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_amt_inc_tax) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_item_sk
),
CustomerReturns AS (
    SELECT 
        ch.c_customer_sk,
        SUM(COALESCE(rd.total_returns, 0)) AS total_customer_returns,
        COUNT(rd.return_count) AS total_return_tickets
    FROM CustomerHierarchy ch
    LEFT JOIN ReturnData rd ON ch.c_customer_sk = rd.sr_customer_sk
    GROUP BY ch.c_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_customer_returns, 0) AS total_returns,
    cr.total_return_tickets,
    sd.total_sales,
    sd.unique_customers
FROM CustomerHierarchy ch
LEFT JOIN CustomerReturns cr ON ch.c_customer_sk = cr.c_customer_sk
LEFT JOIN SalesData sd ON sd.ws_item_sk = ch.c_customer_sk
ORDER BY total_sales DESC, total_returns ASC
FETCH FIRST 50 ROWS ONLY;
