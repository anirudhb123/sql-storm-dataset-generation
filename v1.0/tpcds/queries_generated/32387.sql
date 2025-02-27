
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
    GROUP BY 
        ws_item_sk
),
Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_city
),
Returned_Sales AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
Overall_Sales AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_paid) AS net_sales,
        COALESCE(rs.total_returned, 0) AS total_returned,
        SUM(ss.ss_net_paid) - COALESCE(rs.total_returned, 0) AS net_profit
    FROM 
        store_sales AS ss
    LEFT JOIN Returned_Sales AS rs ON ss.ss_item_sk = rs.sr_item_sk
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    i.i_item_desc,
    os.net_sales,
    os.total_returned,
    os.net_profit,
    cs.order_count AS customer_order_count,
    cs.ca_city
FROM 
    Overall_Sales AS os
JOIN item AS i ON os.ss_item_sk = i.i_item_sk
LEFT JOIN Customer_Sales AS cs ON os.ss_item_sk = cs.c_customer_sk
WHERE 
    os.net_profit > 0
    AND EXISTS (
        SELECT 1
        FROM Sales_CTE s
        WHERE s.ws_item_sk = os.ss_item_sk
        AND s.rnk <= 5
    )
ORDER BY 
    os.net_profit DESC 
LIMIT 10;
