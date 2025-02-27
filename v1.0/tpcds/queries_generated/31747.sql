
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_item_sk
    
    UNION ALL
    
    SELECT 
        st.ws_item_sk,
        SUM(st.ws_quantity) + ss.total_quantity,
        SUM(st.ws_net_paid) + ss.total_revenue,
        COUNT(DISTINCT st.ws_order_number) + ss.total_orders,
        level + 1
    FROM 
        web_sales st
    JOIN 
        sales_summary ss ON st.ws_item_sk = ss.ws_item_sk
    WHERE 
        level < 3
    GROUP BY 
        st.ws_item_sk
),
item_statistics AS (
    SELECT 
        i.i_item_id,
        SUM(COALESCE(ss.total_quantity, 0)) AS total_quantity,
        SUM(COALESCE(ss.total_revenue, 0)) AS total_revenue
    FROM 
        item i
    LEFT JOIN 
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
    GROUP BY 
        i.i_item_id
),
customer_demographics AS (
    SELECT 
        cd_cdemo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    id.i_item_id,
    id.total_quantity,
    id.total_revenue,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    CASE 
        WHEN id.total_revenue > 10000 THEN 'High Value'
        WHEN id.total_revenue > 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS revenue_category
FROM 
    item_statistics id
LEFT JOIN 
    customer_demographics cd ON id.total_quantity > cd.customer_count
ORDER BY 
    id.total_revenue DESC
LIMIT 100;
