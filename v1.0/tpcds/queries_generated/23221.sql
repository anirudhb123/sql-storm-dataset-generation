
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
)
SELECT 
    ca.c_city,
    ca.ca_state,
    cd.cd_gender,
    COALESCE(SUM(ws.wholesale_cost), 0) AS total_wholesale_cost,
    COUNT(CASE WHEN ws.ws_quantity > 10 THEN 1 END) AS high_sales_count,
    (SELECT COUNT(*) FROM customer WHERE c_birth_month = CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE NULL END) AS married_customers
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    RecursiveSales rs ON ws.ws_item_sk = rs.ws_item_sk AND rs.profit_rank <= 5
WHERE 
    ca.ca_country = 'USA' 
    AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
    AND ca.ca_state IN (SELECT w_state FROM warehouse GROUP BY w_state HAVING COUNT(*) > 5)
GROUP BY 
    ca.c_city, ca.ca_state, cd.cd_gender
HAVING 
    total_wholesale_cost > (SELECT AVG(ws.wholesale_cost) FROM web_sales ws WHERE ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023))
ORDER BY 
    ca.c_city, total_wholesale_cost DESC;
