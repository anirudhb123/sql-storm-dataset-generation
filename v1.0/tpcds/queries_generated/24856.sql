
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, hd.hd_income_band_sk
),
order_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(CASE WHEN o.ws_sales_price IS NULL THEN 0 ELSE 1 END) AS valid_orders,
        SUM(o.ws_net_paid_inc_tax) AS sales_total,
        MAX(o.ws_sold_date_sk) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales o ON c.c_customer_sk = o.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
final_report AS (
    SELECT 
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.income_band,
        COALESCE(os.total_orders, 0) AS total_orders,
        COALESCE(os.valid_orders, 0) AS valid_orders,
        COALESCE(total_spent, 0) AS total_spent,
        CASE 
            WHEN COALESCE(total_spent, 0) > 1000 THEN 'High Value'
            WHEN COALESCE(total_spent, 0) > 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        CASE 
            WHEN cd.cd_gender IS NULL THEN 'Unknown'
            ELSE cd.cd_gender
        END AS gender_category,
        ROW_NUMBER() OVER (PARTITION BY cd.income_band ORDER BY total_spent DESC) AS rank_by_spending
    FROM 
        customer_data cd
    LEFT JOIN 
        order_summary os ON cd.c_customer_sk = os.c_customer_sk
    WHERE 
        (cd.cd_marital_status IS NOT NULL OR cd.cd_gender IS NOT NULL)
        AND cd.income_band > 0
)
SELECT 
    f.*,
    STRING_AGG(DISTINCT CONCAT('Order Number: ', ws.ws_order_number) ORDER BY ws.ws_order_number) AS order_details
FROM 
    final_report f
LEFT JOIN 
    web_sales ws ON f.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    f.c_customer_id, f.cd_gender, f.cd_marital_status, f.cd_credit_rating, f.income_band, f.total_orders, f.valid_orders, f.total_spent, f.customer_value, f.gender_category, f.rank_by_spending
HAVING 
    f.rank_by_spending <= 10
ORDER BY 
    f.customer_value DESC, f.total_spent DESC;
