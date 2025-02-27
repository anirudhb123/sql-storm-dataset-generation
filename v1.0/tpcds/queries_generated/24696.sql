
WITH RECURSIVE Profit_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        cs_item_sk
)
SELECT 
    ca_city,
    SUM(total_profit) AS city_total_profit,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    STRING_AGG(DISTINCT ci.item_desc, ', ') AS top_items,
    CASE 
        WHEN round(city_total_profit, 2) IS NULL THEN 'No Profit'
        ELSE 'Profit Recorded'
    END AS profit_status
FROM 
    Profit_CTE pc
JOIN 
    item ci ON pc.ws_item_sk = ci.i_item_sk OR pc.ws_item_sk = ci.i_item_sk
JOIN 
    store s ON s.s_store_sk = (SELECT ss_store_sk FROM store_sales WHERE ss_item_sk = pc.ws_item_sk LIMIT 1)
JOIN 
    (SELECT DISTINCT c_customer_sk, c_current_addr_sk FROM customer) c 
    ON c.c_current_addr_sk = s.s_street_number
JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY 
    ca_city
HAVING 
    SUM(total_profit) > (
        SELECT 
            AVG(total_profit) 
        FROM 
            Profit_CTE 
    )
ORDER BY 
    city_total_profit DESC
LIMIT 5;
