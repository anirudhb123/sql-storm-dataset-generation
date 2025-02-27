
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
customer_demographics AS (
    SELECT 
        cd.ca_address_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status_description
    FROM 
        customer_demographics cd
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cd.cd_gender,
    cd.marital_status_description,
    NTILE(4) OVER (ORDER BY cs.total_sales DESC) AS sales_quartile,
    COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
    CONCAT(cs.c_first_name, ' ', cs.c_last_name) AS full_name,
    CASE 
        WHEN DATEDIFF(CURRENT_DATE, LAST_DAY(CURRENT_DATE) - INTERVAL 1 MONTH) > 0 THEN 'Last Month'
        ELSE 'Current Month'
    END AS sale_period
FROM 
    customer_sales cs
JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.ca_address_sk
LEFT JOIN 
    (SELECT DISTINCT 
        d.d_date,
        d.d_month_seq,
        d.d_year,
        CASE 
            WHEN d.d_dow IN (1, 7) THEN 'Weekend' 
            ELSE 'Weekday' 
        END AS day_type
     FROM 
        date_dim d
     WHERE 
        d.d_date BETWEEN DATE_SUB(CURRENT_DATE, INTERVAL 12 MONTH) AND CURRENT_DATE) AS date_info ON date_info.d_month_seq = MONTH(CURRENT_DATE)
WHERE 
    cs.total_sales > 500
ORDER BY 
    total_sales DESC
LIMIT 10;
