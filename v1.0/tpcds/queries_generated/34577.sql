
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_bill_customer_sk
), 
Customer_Demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_customer_sk,
        c.c_birth_year,
        coalesce(MAX(cd.cd_purchase_estimate), 0) AS estimated_purchase
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, c.c_customer_sk, c.c_birth_year
),
Top_Customers AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        sr.sr_return_quantity,
        COALESCE(S.active_customers, 0) AS active_customers
    FROM Customer_Demo cd
    LEFT JOIN (
        SELECT 
            ws_bill_customer_sk,
            COUNT(DISTINCT ws_order_number) AS active_customers
        FROM web_sales
        WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
        GROUP BY ws_bill_customer_sk
    ) S ON cd.c_customer_sk = S.ws_bill_customer_sk
    LEFT JOIN store_returns sr ON cd.c_customer_sk = sr.sr_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
)
SELECT 
    tc.c_customer_sk,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    SUM(tc.sr_return_quantity) AS total_returns,
    SUM(tc.estimated_purchase) AS total_estimated_purchase,
    COUNT(tc.sr_return_quantity) AS return_count
FROM Top_Customers tc
GROUP BY 
    tc.c_customer_sk,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status
HAVING SUM(tc.sr_return_quantity) > 0
ORDER BY total_returns DESC
LIMIT 10;
