
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM 
        item i
    JOIN 
        ranked_sales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE 
        rs.rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COALESCE(hd.hd_dep_count, 0) AS dep_count
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    COALESCE(MAX(ti.total_sales), 0) AS max_sales,
    COUNT(DISTINCT ti.i_item_id) AS unique_items_purchased,
    SUM(ti.total_sales) AS total_spent,
    CASE 
        WHEN ci.dep_count > 0 THEN 'Has Dependents' 
        ELSE 'No Dependents' 
    END AS dependent_status
FROM 
    customer_info ci
LEFT JOIN 
    top_items ti ON ci.c_customer_id IN (
        SELECT 
            DISTINCT ws_bill_customer_sk 
        FROM 
            web_sales
        WHERE 
            ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    )
GROUP BY 
    ci.c_customer_id, ci.c_first_name, ci.c_last_name, ci.dep_count
ORDER BY 
    total_spent DESC;
