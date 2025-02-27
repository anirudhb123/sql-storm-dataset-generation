
WITH RECURSIVE sales_totals AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price - ws_ext_discount_amt) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS ranking
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        st.ws_item_sk,
        st.total_sales
    FROM sales_totals st
    WHERE st.ranking <= 10
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        smb.sm_type,
        SUM(ws.ws_quantity) AS total_purchases
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN ship_mode smb ON ws.ws_ship_mode_sk = smb.sm_ship_mode_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_gender, smb.sm_type
),
address_stats AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY ca.ca_state
)
SELECT 
    cd.c_first_name AS first_name,
    cd.c_last_name AS last_name,
    cd.cd_marital_status AS marital_status,
    cd.cd_gender AS gender,
    TOP_ITEMS.total_sales AS top_sales,
    AS.stats.customer_count AS customers_in_state,
    AS.stats.avg_vehicle_count AS avg_vehicle_count
FROM customer_details cd
JOIN top_items ON cd.ws_item_sk = top_items.ws_item_sk
JOIN address_stats AS stats ON cd.c_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk IN (SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_state = stats.ca_state))
WHERE 
    cd.total_purchases > 
    (SELECT AVG(total_purchases) FROM customer_details)
ORDER BY top_sales DESC
LIMIT 100;
