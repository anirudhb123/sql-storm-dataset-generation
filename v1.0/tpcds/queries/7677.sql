
WITH Total_Sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
Customer_Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 1000
),
Top_Customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.total_sales,
        d.total_orders
    FROM 
        customer AS c
    JOIN 
        Total_Sales AS d ON c.c_customer_sk = d.ws_bill_customer_sk
    WHERE 
        d.total_sales > (SELECT AVG(total_sales) FROM Total_Sales)
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    tc.total_sales,
    tc.total_orders
FROM 
    Top_Customers AS tc
JOIN 
    Customer_Demographics AS cd ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = tc.c_customer_sk)
ORDER BY 
    tc.total_sales DESC, tc.total_orders DESC
FETCH FIRST 10 ROWS ONLY;
