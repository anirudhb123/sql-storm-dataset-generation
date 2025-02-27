
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ss_item_sk,
        SUM(ss_net_profit) AS total_profit,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
    UNION ALL
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        level + 1
    FROM 
        web_sales
    WHERE 
        ws_item_sk NOT IN (SELECT ss_item_sk FROM store_sales)
    GROUP BY 
        ws_item_sk
    HAVING 
        COUNT(ws_order_number) > 1
),
Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Ranked_Customers AS (
    SELECT 
        c.customer_sk,
        c.total_web_sales,
        c.total_store_sales,
        RANK() OVER (ORDER BY (c.total_web_sales + c.total_store_sales) DESC) AS sales_rank
    FROM 
        Customer_Sales c
)
SELECT 
    a.ca_city,
    COUNT(DISTINCT rc.customer_sk) AS num_ranked_customers,
    AVG(rc.total_web_sales + rc.total_store_sales) AS avg_sales,
    MAX(rc.sales_rank) AS max_sales_rank
FROM 
    customer_address a
JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN 
    Ranked_Customers rc ON c.c_customer_sk = rc.customer_sk
WHERE 
    a.ca_state = 'CA' 
    AND (rc.total_web_sales + rc.total_store_sales) BETWEEN 100 AND 10000
GROUP BY 
    a.ca_city
ORDER BY 
    num_ranked_customers DESC
LIMIT 10;
