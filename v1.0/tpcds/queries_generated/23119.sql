
WITH RecursiveSales AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws_web_page_sk ORDER BY ws_ext_sales_price DESC) as rank_sales
    FROM web_sales ws
    WHERE ws_sales_price IS NOT NULL
), 
CustomerReturnCounts AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(DISTINCT sr_order_number) as return_count,
        SUM(sr_return_amt_inc_tax) as total_return_amount
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
TopReturningCustomers AS (
    SELECT 
        cr.returning_customer_sk,
        cr.return_count,
        cr.total_return_amount
    FROM CustomerReturnCounts cr
    WHERE cr.return_count > (
        SELECT AVG(return_count) 
        FROM CustomerReturnCounts
    )
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(ws.net_profit) AS total_net_profit,
    COALESCE(SUM(CASE WHEN ws.ws_sales_price > 20.00 THEN 1 ELSE 0 END), 0) AS high_value_sales,
    AVG(CASE 
            WHEN ws.ws_sales_price < 5.00 THEN NULL 
            ELSE ws.ws_sales_price 
        END) AS avg_non_low_value_sales,
    COUNT(DISTINCT tc.returning_customer_sk) AS top_return_customers
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN TopReturningCustomers tc ON c.c_customer_sk = tc.returning_customer_sk
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_sk) > 10 
   AND SUM(ws.net_profit) IS NOT NULL 
   AND (SELECT COUNT(*) FROM inventory WHERE inv_quantity_on_hand IS NOT NULL) > 100
ORDER BY total_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
