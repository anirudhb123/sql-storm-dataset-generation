
WITH ranked_returns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        DENSE_RANK() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
customer_profiles AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.cd_gender,
        cp.cd_marital_status,
        cp.cd_education_status,
        cp.cd_purchase_estimate,
        rr.total_return_amt,
        rr.return_count
    FROM 
        customer_profiles cp
    JOIN 
        ranked_returns rr ON cp.c_customer_sk = rr.sr_returning_customer_sk
    WHERE 
        rr.rank = 1 AND rr.total_return_amt > 1000
),
sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
)
SELECT 
    hvc.c_customer_sk,
    CONCAT(hvc.c_first_name, ' ', hvc.c_last_name) AS customer_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    hvc.cd_purchase_estimate,
    ss.total_sales,
    ss.total_orders
FROM 
    high_value_customers hvc
JOIN 
    sales_summary ss ON hvc.c_customer_sk = ss.web_site_sk
ORDER BY 
    ss.total_sales DESC, hvc.cd_purchase_estimate DESC;
