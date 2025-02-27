
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),

customer_details AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
)

SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    customer_sales cs
JOIN 
    customer_details cd ON cd.cd_demo_sk = cs.c_customer_sk
LEFT JOIN 
    income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
WHERE 
    cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
    AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
ORDER BY 
    cs.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
