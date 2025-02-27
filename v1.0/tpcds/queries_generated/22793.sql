
WITH RECURSIVE CustomerChain AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, 
           cd.cd_gender, cd.cd_dep_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_dep_count DESC) as rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_dep_count IS NOT NULL
    UNION ALL
    SELECT cc.c_customer_sk, cc.c_first_name, cc.c_last_name, cd.cd_marital_status, 
           cd.cd_gender, cd.cd_dep_count,
           ROW_NUMBER() OVER (PARTITION BY cc.c_customer_sk ORDER BY cd.cd_dep_count ASC) as rn
    FROM customer c
    JOIN customer cc ON c.c_customer_sk < cc.c_customer_sk
    JOIN customer_demographics cd ON cc.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M' AND cd.cd_dep_count < (
        SELECT MAX(cd2.cd_dep_count) 
        FROM customer c2
        JOIN customer_demographics cd2 ON c2.c_current_cdemo_sk = cd2.cd_demo_sk
        WHERE c2.c_customer_sk = c.c_customer_sk
    )
)

SELECT 
    ca.ca_city,
    COUNT(DISTINCT cc.c_customer_sk) AS Total_Customers,
    AVG(cd.cd_dep_count) AS Avg_Dependents,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS Married_Count
FROM CustomerChain cc
JOIN customer_address ca ON cc.c_customer_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cc.c_customer_sk = cd.cd_demo_sk
GROUP BY ca.ca_city
HAVING AVG(CASE WHEN cd.cd_dep_count IS NULL THEN 0 ELSE cd.cd_dep_count END) > 
           (SELECT AVG(cd2.cd_dep_count) FROM customer_demographics cd2 WHERE cd2.cd_gender = 'M')
ORDER BY Total_Customers DESC
LIMIT 10;

SELECT 
    sm.sm_type AS Shipping_Method,
    SUM(ws.ws_net_profit) AS Total_Profit
FROM web_sales ws
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ws.ws_net_paid_inc_ship > (SELECT AVG(ws2.ws_net_paid_inc_ship) FROM web_sales ws2 WHERE ws2.ws_sold_date_sk > 10000)
GROUP BY sm.sm_type
HAVING COUNT(ws.ws_order_number) > 5
INTERSECT
SELECT 
    sm.sm_type AS Shipping_Method,
    SUM(cs.cs_net_profit) AS Catalog_Profit
FROM catalog_sales cs
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY sm.sm_type
HAVING AVG(cs.cs_net_paid_inc_ship) > 1000;

SELECT 
    DISTINCT wp.wp_url || ' - ' || COALESCE(NULLIF(wp.wp_type, ''), 'Unknown') AS Page_Info,
    COUNT(DISTINCT wr.wr_order_number) AS Total_Returns
FROM web_page wp
LEFT JOIN web_returns wr ON wp.wp_web_page_sk = wr.wr_web_page_sk
WHERE wp.wp_creation_date_sk BETWEEN 1 AND 100
GROUP BY wp.wp_url, wp.wp_type
HAVING COUNT(DISTINCT wr.wr_order_number) > 0;
