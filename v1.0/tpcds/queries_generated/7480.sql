
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
DemographicData AS (
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
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.total_sales,
        s.order_count,
        s.last_purchase_date,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate
    FROM 
        SalesData s
    JOIN 
        customer c ON s.customer_sk = c.c_customer_sk
    JOIN 
        DemographicData d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE 
        s.total_sales > (SELECT AVG(total_sales) FROM SalesData)
    ORDER BY 
        s.total_sales DESC
    LIMIT 100
)
SELECT 
    t.c_customer_id,
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.order_count,
    t.last_purchase_date,
    t.cd_gender,
    t.cd_marital_status,
    t.cd_education_status,
    t.cd_purchase_estimate,
    COUNT(sr_item_sk) AS total_returns,
    SUM(sr_return_amt) AS total_return_amount
FROM 
    TopCustomers t
LEFT JOIN 
    store_returns sr ON t.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_customer_sk = sr.sr_customer_sk)
GROUP BY 
    t.c_customer_id, t.c_first_name, t.c_last_name,
    t.total_sales, t.order_count, t.last_purchase_date,
    t.cd_gender, t.cd_marital_status, t.cd_education_status, t.cd_purchase_estimate
ORDER BY 
    total_returns DESC
LIMIT 50;
