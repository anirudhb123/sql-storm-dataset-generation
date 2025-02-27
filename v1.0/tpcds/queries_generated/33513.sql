
WITH RECURSIVE sales_trends AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ranked_sales AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        sales_trends
),
top_items AS (
    SELECT 
        ri.ws_item_sk,
        i.i_item_desc,
        i.i_current_price,
        ri.total_quantity,
        ri.total_revenue,
        il.ib_lower_bound,
        il.ib_upper_bound
    FROM 
        ranked_sales ri
    JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = (SELECT cd_demo_sk FROM customer_demographics WHERE cd_demo_sk = i.i_item_sk)
    LEFT JOIN 
        income_band il ON il.ib_income_band_sk = hd.hd_income_band_sk 
    WHERE 
        revenue_rank <= 10
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS customer_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk
),
final_results AS (
    SELECT 
        ti.i_item_desc,
        ti.total_quantity,
        ti.total_revenue,
        cs.customer_revenue,
        cs.order_count,
        COALESCE(ROUND(cs.customer_revenue / (NULLIF(ti.total_revenue, 0)), 2), 0) AS customer_revenue_share
    FROM 
        top_items ti
    LEFT JOIN 
        customer_sales cs ON ti.ws_item_sk = cs.c_customer_sk
)
SELECT 
    f.i_item_desc,
    f.total_quantity,
    f.total_revenue,
    f.customer_revenue,
    f.order_count,
    CASE 
        WHEN f.customer_revenue_share IS NULL THEN 'No Sales'
        ELSE CONCAT(ROUND(f.customer_revenue_share * 100, 2), '% of Total Revenue')
    END AS revenue_percentage
FROM 
    final_results f
WHERE 
    f.customer_revenue > 1000
ORDER BY 
    f.total_revenue DESC;
