
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_ext_discount_amt) AS total_discounts
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458623 AND 2458629 -- Assuming these correspond to a week of interest
    GROUP BY 
        ws_bill_customer_sk
),
CustomerAggregates AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band AS income_band,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count,
        COALESCE(sd.total_discounts, 0) AS total_discounts
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        *,
        CASE 
            WHEN total_sales > 1000 THEN 'High Value'
            WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM 
        CustomerAggregates
)
SELECT 
    income_band,
    customer_value_category,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS average_sales,
    SUM(total_discounts) AS total_discounts
FROM 
    HighValueCustomers
GROUP BY 
    income_band, customer_value_category
ORDER BY 
    income_band, customer_value_category DESC;
