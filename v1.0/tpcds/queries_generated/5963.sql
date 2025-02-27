
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY c.c_current_cdemo_sk DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating = 'Good'
), sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_sales_price) AS total_sales 
    FROM 
        web_sales ws
    JOIN 
        ranked_customers rc ON ws.ws_bill_customer_sk = rc.c_customer_id
    GROUP BY 
        ws.ws_bill_customer_sk
), customer_ranks AS (
    SELECT 
        rc.c_customer_id, 
        rc.c_first_name, 
        rc.c_last_name, 
        ss.total_quantity, 
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        ranked_customers rc
    JOIN 
        sales_summary ss ON rc.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    cr.c_customer_id, 
    cr.c_first_name, 
    cr.c_last_name, 
    cr.total_quantity, 
    cr.total_sales, 
    cr.sales_rank
FROM 
    customer_ranks cr
WHERE 
    cr.sales_rank <= 10
ORDER BY 
    cr.total_sales DESC;
