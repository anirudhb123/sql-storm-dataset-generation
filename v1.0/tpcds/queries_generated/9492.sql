
WITH customer_stats AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd_purchase_estimate > 1000 THEN 1 ELSE 0 END) AS high_value_customers
    FROM 
        customer_demographics
    LEFT JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
sales_summary AS (
    SELECT 
        d_year,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
),
inventory_status AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory
    JOIN 
        item ON inv_item_sk = i_item_sk
    GROUP BY 
        i_item_sk, i_item_desc
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    ss.d_year,
    ss.total_sales,
    ss.total_profit,
    ss.total_orders,
    SUM(is.total_quantity_on_hand) AS total_inventory
FROM 
    customer_stats cs
JOIN 
    sales_summary ss ON cs.cd_demo_sk = ss.d_year
JOIN 
    inventory_status is ON cs.cd_demo_sk = is.i_item_sk
GROUP BY 
    cs.cd_gender, cs.cd_marital_status, ss.d_year
ORDER BY 
    ss.total_sales DESC, total_inventory DESC
LIMIT 10;
