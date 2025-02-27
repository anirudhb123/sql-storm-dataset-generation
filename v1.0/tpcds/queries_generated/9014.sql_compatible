
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
demographics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_country
),
final_report AS (
    SELECT 
        d.c_customer_id,
        ds.cd_gender,
        ds.cd_marital_status,
        ds.cd_education_status,
        ds.cd_purchase_estimate,
        ss.total_quantity,
        ss.total_net_profit,
        ss.order_count,
        ai.customer_count,
        ai.ca_country
    FROM 
        sales_summary AS ss
    JOIN 
        demographics AS ds ON ss.ws_bill_customer_sk = ds.c_customer_id
    JOIN 
        address_info AS ai ON ds.c_customer_id IN (SELECT c.c_customer_id FROM customer c WHERE c.c_current_addr_sk IN (SELECT ca.ca_address_sk FROM customer_address ca))
    WHERE 
        ss.total_net_profit > 1000
)
SELECT 
    *,
    (total_net_profit / NULLIF(total_quantity, 0)) AS avg_net_profit_per_item
FROM 
    final_report
ORDER BY 
    total_net_profit DESC
LIMIT 100;
