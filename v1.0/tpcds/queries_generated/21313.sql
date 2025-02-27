
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_order_number, 
        ws_quantity * (CASE WHEN ws_sales_price > 0 THEN 1 ELSE 0 END) AS quantity_sold,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2400 AND 3000
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        cs_order_number,
        cs_quantity * (CASE WHEN cs_sales_price > 0 THEN 1 ELSE 0 END) AS quantity_sold,
        cs_sales_price,
        cs_net_profit
    FROM 
        catalog_sales
    WHERE 
        cs_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_net_profit IS NOT NULL)
        AND cs_sold_date_sk > (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_item_sk = cs_item_sk)
),
Aggregated_Sales AS (
    SELECT 
        ws_item_sk,
        SUM(quantity_sold) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        Sales_CTE
    WHERE 
        rn = 1
    GROUP BY 
        ws_item_sk
),
Customer_Preference AS (
    SELECT 
        c_customer_id,
        MAX(cd_dep_count) AS max_dependents,
        MIN(cd_credit_rating) AS min_credit_rating,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    JOIN 
        customer ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        c_customer_id
)
SELECT 
    ca.ca_city,
    sa.ws_item_sk,
    sa.total_quantity,
    sa.total_net_profit,
    cp.max_dependents,
    cp.min_credit_rating
FROM 
    customer_address ca
LEFT JOIN 
    Aggregated_Sales sa ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = sa.ws_item_sk LIMIT 1)
INNER JOIN 
    Customer_Preference cp ON cp.demographic_count > 1 AND cp.max_dependents IS NOT NULL
WHERE 
    ca.ca_country IS NOT NULL
    AND ca.ca_zip IN (SELECT DISTINCT ca_zip FROM customer_address WHERE ca_state = 'CA' UNION SELECT NULL)
ORDER BY 
    total_net_profit DESC NULLS LAST;
