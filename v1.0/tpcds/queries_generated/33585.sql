
WITH RECURSIVE Address_Chain AS (
    SELECT ca_address_sk, ca_city, ca_state
    FROM customer_address
    WHERE ca_state IS NOT NULL

    UNION ALL

    SELECT ca_address_sk, ca_city, ca_state
    FROM customer_address ca
    JOIN Address_Chain ac ON ac.ca_city = ca.ca_city AND ac.ca_state = ca.ca_state
    WHERE ca.ca_address_sk <> ac.ca_address_sk
),

Sales_Summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws_order_number) AS num_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1000 AND 1500
    GROUP BY ws_item_sk
),

Customer_Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        SUM(cd_dep_count) AS total_dependents
    FROM customer_demographics
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
),

Combined_Sales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(ss_net_profit) AS total_store_profit
    FROM store_sales
    GROUP BY ss_item_sk
)

SELECT 
    cs.sold_item_sk,
    COALESCE(ws.total_sales, 0) AS web_total_sales,
    COALESCE(ss.total_store_sales, 0) AS store_total_sales,
    (COALESCE(ws.total_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS overall_total_sales,
    ad.ca_city,
    ad.ca_state,
    cd.total_dependents,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_desc
FROM Sales_Summary ws
FULL OUTER JOIN Combined_Sales ss ON ws.ws_item_sk = ss.ss_item_sk
JOIN Address_Chain ad ON  ad.ca_city IN ('New York', 'Los Angeles')
LEFT JOIN Customer_Demographics cd ON cd.cd_demo_sk IN (SELECT DISTINCT c_current_cdemo_sk FROM customer WHERE c_current_cdemo_sk IS NOT NULL)
WHERE (ws.total_sales > 1000 OR ss.total_store_sales > 1000)
AND (cd.total_dependents IS NULL OR cd.total_dependents > 3)
ORDER BY overall_total_sales DESC
LIMIT 100;
