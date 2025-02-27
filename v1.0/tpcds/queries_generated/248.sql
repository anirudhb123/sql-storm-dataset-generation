
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.item_sk,
        ws.quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.buy_potential,
        COALESCE(SUM(rs.ws_net_paid), 0) AS total_spent,
        COUNT(rs.item_sk) AS items_purchased,
        AVG(rs.ws_net_paid) AS avg_spent_per_item
    FROM 
        customer_info ci
    LEFT JOIN ranked_sales rs ON ci.c_customer_sk = rs.bill_customer_sk AND rs.sales_rank <= 10
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.buy_potential
)
SELECT 
    ss.*,
    CASE 
        WHEN ss.total_spent > 1000 THEN 'High Value'
        WHEN ss.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    sales_summary ss
WHERE 
    EXISTS (
        SELECT 1 
        FROM store s
        WHERE s.s_store_sk IN (SELECT DISTINCT ws.w_warehouse_sk FROM web_sales ws WHERE ws.bill_customer_sk = ss.c_customer_sk)
          AND s.s_number_employees > 10
    )
ORDER BY 
    ss.total_spent DESC;
