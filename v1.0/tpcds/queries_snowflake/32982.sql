
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS revenue_rank
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        sales_cte.total_quantity,
        sales_cte.total_revenue
    FROM 
        sales_cte
    JOIN 
        item ON sales_cte.ss_item_sk = item.i_item_sk
    JOIN 
        customer c ON c.c_customer_sk = (
            SELECT 
                ss_customer_sk 
            FROM 
                store_sales 
            WHERE 
                ss_item_sk = sales_cte.ss_item_sk
            ORDER BY 
                ss_net_paid DESC 
            LIMIT 1
        )
    WHERE 
        sales_cte.revenue_rank <= 10
),
customer_stats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
total_revenue AS (
    SELECT 
        SUM(ws_net_paid) AS total_web_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.c_first_name,
    ti.c_last_name,
    cs.cd_gender,
    cs.customer_count,
    cs.avg_purchase_estimate,
    tr.total_web_revenue
FROM 
    top_items ti
JOIN 
    customer_stats cs ON 1=1
CROSS JOIN 
    total_revenue tr
ORDER BY 
    ti.total_revenue DESC;
