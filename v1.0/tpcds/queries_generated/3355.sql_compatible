
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sale_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_income_band_sk,
        COALESCE(cd.cd_dep_count, 0) AS dep_count
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
ranked_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_income_band_sk,
        ci.dep_count,
        RANK() OVER (PARTITION BY ci.cd_income_band_sk ORDER BY SUM(ws.total_sales) DESC) AS customer_rank
    FROM 
        customer_info ci
    JOIN ranked_sales ws ON ci.c_customer_sk = ws.ws_item_sk
    GROUP BY 
        ci.c_customer_sk, ci.cd_gender, ci.cd_income_band_sk, ci.dep_count
)
SELECT 
    rc.c_customer_sk,
    rc.cd_gender,
    rc.cd_income_band_sk,
    rc.dep_count,
    rs.total_sales,
    CASE 
        WHEN rc.dep_count IS NULL THEN 'Unknown'
        ELSE 'Known'
    END AS dependency_status
FROM 
    ranked_customers rc
JOIN ranked_sales rs ON rc.c_customer_sk = rs.ws_item_sk
WHERE 
    rc.customer_rank <= 5
ORDER BY 
    rs.total_sales DESC;
