
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 5
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM web_sales ws
    GROUP BY ws.ws_order_number
),
ReturnsData AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(sr_ticket_number) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
),
AggregateSales AS (
    SELECT 
        sd.ws_order_number,
        sd.total_sales,
        sd.unique_customers,
        sd.avg_profit,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        COALESCE(rd.total_returns, 0) AS total_returns
    FROM SalesData sd
    LEFT JOIN ReturnsData rd ON sd.ws_order_number = rd.sr_item_sk
),
FinalReport AS (
    SELECT 
        ch.c_first_name || ' ' || ch.c_last_name AS customer_name,
        asd.ws_order_number,
        asd.total_sales,
        asd.unique_customers,
        asd.avg_profit,
        asd.total_return_amount,
        asd.total_returns
    FROM CustomerHierarchy ch
    JOIN AggregateSales asd ON ch.c_customer_sk = asd.ws_order_number
)
SELECT 
    FR.customer_name,
    FR.total_sales,
    FR.unique_customers,
    FR.avg_profit,
    FR.total_return_amount,
    FR.total_returns,
    CASE 
        WHEN FR.total_sales > 10000 THEN 'High Sales'
        WHEN FR.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM FinalReport FR
ORDER BY FR.avg_profit DESC, FR.total_sales DESC;
