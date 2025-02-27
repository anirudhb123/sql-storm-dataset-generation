
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, hd.hd_income_band_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        cs.spending_rank
    FROM 
        customer_summary cs
    WHERE 
        cs.spending_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(SUM(ws.ws_ext_tax), 0) AS total_tax,
    COALESCE(SUM(ws.ws_ext_discount_amt), 0) AS total_discount,
    (SELECT 
        COUNT(DISTINCT wr.wr_order_number) 
     FROM web_returns wr 
     WHERE wr.wr_returning_customer_sk = tc.c_customer_sk
    ) AS total_returns,
    CASE 
        WHEN tc.total_spent > 1000 THEN 'High Value'
        WHEN tc.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    top_customers tc
LEFT JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_spent;
