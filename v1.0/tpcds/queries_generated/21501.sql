
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank_sales
    FROM web_sales
    GROUP BY ws_item_sk
),
inventory_state AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        SUM(CASE WHEN inv_quantity_on_hand < 10 THEN 1 ELSE 0 END) AS low_stock_count
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk
),
customer_demographics AS (
    SELECT 
        cd_demo_sk,
        (CASE 
            WHEN cd_income_band_sk IS NULL THEN 'Unknown'
            ELSE (SELECT ib_lower_bound || '-' || ib_upper_bound FROM income_band WHERE ib_income_band_sk = cd_income_band_sk)
        END) AS income_band,
        cd_gender,
        cd_marital_status,
        (SELECT AVG(cd_purchase_estimate) OVER (PARTITION BY cd_gender) FROM customer_demographics) AS avg_purchase
    FROM customer_demographics
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cd.income_band,
    cd.cd_gender,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY COUNT(DISTINCT ws.ws_order_number) DESC) AS order_rank,
    COALESCE((SELECT COUNT(*) FROM inventory_state IS inv WHERE inv.inv_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)), 0) AS low_stock_alert
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN ranked_sales rs ON ws.ws_item_sk = rs.ws_item_sk AND rs.rank_sales = 1
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F' 
AND (ca.ca_city LIKE 'New%' OR ca.ca_city IS NULL)
GROUP BY c.c_customer_id, ca.ca_city, cd.income_band, cd.cd_gender
HAVING total_orders > (SELECT AVG(total_orders) FROM (SELECT COUNT(DISTINCT ws_order_number) AS total_orders FROM web_sales GROUP BY ws_bill_customer_sk))
ORDER BY total_revenue DESC, c.c_customer_id
LIMIT 10;
