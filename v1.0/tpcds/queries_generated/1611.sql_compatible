
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
sales_metrics AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_quantity,
        cs.avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs.cd_income_band_sk ORDER BY cs.total_quantity DESC) AS rank_within_income,
        RANK() OVER (ORDER BY cs.total_quantity DESC) AS overall_rank
    FROM customer_summary cs
    WHERE cs.total_quantity > 0
),
top_customers AS (
    SELECT 
        sm.c_customer_sk,
        sm.total_quantity,
        sm.avg_sales_price,
        CEA.ca_city,
        CEA.ca_state,
        CEA.ca_country
    FROM sales_metrics sm
    INNER JOIN customer_address CEA ON sm.c_customer_sk = CEA.ca_address_sk
    WHERE sm.rank_within_income <= 5
)
SELECT 
    tc.c_customer_sk,
    tc.total_quantity,
    tc.avg_sales_price,
    COALESCE(tc.ca_city, 'Unknown') AS city,
    COALESCE(tc.ca_state, 'Unknown') AS state,
    COALESCE(tc.ca_country, 'Unknown') AS country,
    CASE 
        WHEN tc.total_quantity > 100 THEN 'High Value'
        WHEN tc.total_quantity > 50 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM top_customers tc
WHERE tc.avg_sales_price IS NOT NULL
ORDER BY tc.total_quantity DESC;
