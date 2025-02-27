
WITH RECURSIVE CustomerReturnData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(sr_return_amt), 0) DESC) AS rn
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopReturningCustomers AS (
    SELECT * 
    FROM CustomerReturnData 
    WHERE rn <= 5
),
StoreStatistics AS (
    SELECT 
        s.s_store_sk,
        COUNT(DISTINCT sr.sr_item_sk) AS unique_returned_items,
        AVG(sr_return_quantity) AS avg_return_quantity,
        MAX(sr_return_amt) AS max_return_amount
    FROM store s
    LEFT JOIN store_returns sr ON s.s_store_sk = sr.s_store_sk
    GROUP BY s.s_store_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_moy = 12)
    GROUP BY ws.ws_sold_date_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    r.total_returns,
    r.total_return_amount,
    s.unique_returned_items,
    s.avg_return_quantity,
    s.max_return_amount,
    SUM(ss.total_sales) AS end_of_year_sales,
    SUM(ss.total_profit) AS end_of_year_profit,
    CASE 
        WHEN r.total_return_amount IS NULL THEN 'No Returns'
        WHEN r.total_return_amount = 0 THEN 'Zero Returns'
        ELSE 'Has Returns'
    END AS return_status
FROM TopReturningCustomers r
JOIN StoreStatistics s ON r.c_customer_sk = s.s_store_sk
LEFT JOIN SalesSummary ss ON DATE_FORMAT(NOW(), '%Y') = CAST(ss.ws_sold_date_sk AS CHAR)
WHERE EXISTS (SELECT 1 FROM warehouse w WHERE w.w_warehouse_sk = s.s_store_sk)
GROUP BY c.c_first_name, c.c_last_name, r.total_returns, r.total_return_amount, s.unique_returned_items, s.avg_return_quantity, s.max_return_amount
HAVING SUM(ss.total_sales) > 1000
ORDER BY return_status, r.total_return_amount DESC;
