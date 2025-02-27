
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2022 AND d_current_month = 'Y'
        )
    GROUP BY 
        ws_item_sk
),
Address_CTE AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ' ', 
               COALESCE(ca_suite_number, '')) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
High_Profit_Sales AS (
    SELECT 
        sc.ws_item_sk, 
        sc.total_quantity, 
        sc.total_profit, 
        ac.full_address, 
        ac.ca_city, 
        ac.ca_state,
        (CASE 
            WHEN sc.total_profit > 1000 THEN 'High Profit'
            WHEN sc.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
            ELSE 'Low Profit' 
        END) AS profit_category
    FROM 
        Sales_CTE sc
    JOIN 
        store s ON s.s_store_sk = (SELECT s_store_sk FROM store_sales WHERE ss_item_sk = sc.ws_item_sk LIMIT 1)
    LEFT JOIN 
        Address_CTE ac ON ac.ca_address_sk = s.s_store_sk
    WHERE 
        sc.rank <= 10
)
SELECT 
    hps.ws_item_sk, 
    hps.total_quantity, 
    hps.total_profit, 
    hps.full_address, 
    hps.ca_city, 
    hps.ca_state, 
    hps.profit_category
FROM 
    High_Profit_Sales hps
ORDER BY 
    hps.total_profit DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
UNION ALL
SELECT 
    -1 AS ws_item_sk, 
    0 AS total_quantity, 
    0 AS total_profit, 
    'Aggregated Results' AS full_address, 
    NULL AS ca_city, 
    NULL AS ca_state, 
    'Summary' AS profit_category
FROM 
    (SELECT COUNT(*) AS total_sales, SUM(total_profit) AS total_aggregate_profit FROM High_Profit_Sales) aggregated
HAVING 
    SUM(total_aggregate_profit) IS NOT NULL;
