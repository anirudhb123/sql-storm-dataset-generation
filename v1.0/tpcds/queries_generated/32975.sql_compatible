
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY ss.sold_date_sk DESC) AS rn
    FROM 
        store_sales ss
    LEFT JOIN 
        item i ON ss.item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ss.sold_date_sk,
        ss.item_sk
), ranked_sales AS (
    SELECT 
        sc.sold_date_sk,
        sc.item_sk,
        sc.total_net_profit
    FROM 
        sales_cte sc
    WHERE 
        sc.rn = 1
), customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.net_profit, 0) + COALESCE(cs.net_profit, 0)) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.city,
    ca.state,
    COUNT(DISTINCT cs.c_customer_sk) AS num_customers,
    SUM(cs.total_profit) AS aggregate_profit,
    AVG(rs.total_net_profit) AS average_sales_profit
FROM 
    customer_address ca
FULL OUTER JOIN 
    customer_sales cs ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = cs.c_customer_sk)
LEFT JOIN 
    ranked_sales rs ON rs.item_sk IN (SELECT ws.item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = cs.c_customer_sk)
WHERE 
    ca.state IS NOT NULL
    AND (ca.city ILIKE '%town%' OR ca.city ILIKE '%city%')
GROUP BY 
    ca.city, 
    ca.state
ORDER BY 
    aggregate_profit DESC, 
    num_customers DESC
LIMIT 50;
