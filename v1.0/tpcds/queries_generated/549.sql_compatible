
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND (dd.d_current_month = '1' OR dd.d_current_month = '2')
    GROUP BY 
        ws.web_site_sk, ws_item_sk
),
top_sales AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        ranked_sales rs
    WHERE 
        rs.rank <= 5
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_with_customers AS (
    SELECT 
        ts.total_quantity,
        ts.total_sales,
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        top_sales ts
    INNER JOIN 
        web_site ws ON ts.web_site_sk = ws.web_site_sk
    LEFT JOIN 
        customer_info ci ON ts.ws_item_sk = ci.c_customer_id
    LEFT JOIN 
        income_band ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    COALESCE(ci.c_first_name, 'Unknown') AS first_name,
    COALESCE(ci.c_last_name, 'Unknown') AS last_name,
    ci.cd_gender,
    SUM(swc.total_sales) AS total_spent,
    COUNT(swc.ws_item_sk) AS items_purchased,
    CASE 
        WHEN SUM(swc.total_sales) BETWEEN 0 AND 100 THEN 'Low Spender'
        WHEN SUM(swc.total_sales) BETWEEN 101 AND 500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM 
    sales_with_customers swc
JOIN 
    customer_info ci ON swc.c_customer_id = ci.c_customer_id
GROUP BY 
    ci.c_first_name, ci.c_last_name, ci.cd_gender
ORDER BY 
    total_spent DESC
LIMIT 10;
