
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_id
),
final_report AS (
    SELECT 
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders,
        ws.w_warehouse_id,
        ws.total_inventory
    FROM customer_data cd
    LEFT JOIN sales_data sd ON cd.c_customer_id = sd.ws_bill_customer_sk
    CROSS JOIN warehouse_summary ws
)
SELECT 
    c_customer_id,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    cd_credit_rating,
    ca_city,
    ca_state,
    ca_country,
    total_sales,
    total_orders,
    w_warehouse_id,
    total_inventory
FROM final_report
WHERE total_sales > 10000
ORDER BY total_sales DESC, ca_city ASC
LIMIT 100;
