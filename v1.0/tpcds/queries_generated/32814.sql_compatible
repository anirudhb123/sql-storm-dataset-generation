
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        ss.total_sales,
        ss.total_revenue,
        ROW_NUMBER() OVER (ORDER BY ss.total_revenue DESC) AS revenue_rank
    FROM sales_summary ss
    JOIN item i ON ss.ws_item_sk = i.i_item_sk
    WHERE ss.total_sales > 100
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_by_city AS (
    SELECT 
        ca.ca_city,
        SUM(ws.ws_net_paid) AS city_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_city
),
final_report AS (
    SELECT 
        ti.i_item_id,
        ti.total_sales,
        ti.total_revenue,
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        sb.city_sales,
        sb.order_count
    FROM top_items ti
    JOIN customer_info ci ON ci.gender_rank <= 5
    JOIN sales_by_city sb ON ci.ca_city = sb.ca_city
)
SELECT 
    fr.i_item_id,
    fr.total_sales,
    fr.total_revenue,
    fr.c_customer_id,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.cd_purchase_estimate,
    fr.city_sales,
    fr.order_count
FROM final_report fr
WHERE fr.total_revenue > (
    SELECT AVG(total_revenue) 
    FROM final_report
    WHERE cd_marital_status = 'M'
) OR fr.cd_gender IS NULL
ORDER BY fr.total_revenue DESC
LIMIT 50;
