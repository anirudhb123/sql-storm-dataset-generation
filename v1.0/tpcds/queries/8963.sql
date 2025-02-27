
WITH sales_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_paid) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    GROUP BY 
        s.s_store_sk
),
demographics_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
        MAX(cd.cd_dep_count) AS max_dependents
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
),
combined_summary AS (
    SELECT 
        ss.s_store_sk,
        ds.total_customers,
        ds.average_purchase_estimate,
        ds.max_dependents,
        ss.total_sales_quantity,
        ss.total_sales_amount,
        ss.total_orders,
        ss.average_order_value
    FROM 
        sales_summary ss
    JOIN 
        demographics_summary ds ON ds.cd_demo_sk = (SELECT cd_demo_sk FROM customer WHERE c_current_addr_sk = ss.s_store_sk LIMIT 1)
)
SELECT 
    s.s_store_name,
    cs.total_customers,
    cs.average_purchase_estimate,
    cs.max_dependents,
    cs.total_sales_quantity,
    cs.total_sales_amount,
    cs.total_orders,
    cs.average_order_value
FROM 
    store s
JOIN 
    combined_summary cs ON s.s_store_sk = cs.s_store_sk
WHERE 
    cs.total_sales_amount > 10000
ORDER BY 
    cs.total_sales_amount DESC
LIMIT 10;
