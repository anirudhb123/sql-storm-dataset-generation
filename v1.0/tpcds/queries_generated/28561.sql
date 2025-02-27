
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateDetails AS (
    SELECT 
        d.d_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_year
    FROM 
        date_dim d
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
),
SalesStatistics AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        DateDetails dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.ws_bill_customer_sk
),
FilteredCustomers AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        ss.total_orders,
        ss.total_sales
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesStatistics ss ON cd.c_customer_id = ss.ws_bill_customer_sk
    WHERE 
        ss.total_orders IS NOT NULL 
        AND cd.ca_state = 'CA' 
        AND cd.cd_gender = 'F'
)
SELECT 
    fc.full_name,
    fc.total_orders,
    fc.total_sales,
    CONCAT(SUBSTRING(fc.full_name, 1, 1), '. ', SUBSTRING_INDEX(fc.full_name, ' ', -1)) AS abbreviated_name,
    CASE 
        WHEN fc.total_sales > 1000 THEN 'High Value'
        WHEN fc.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    FilteredCustomers fc
ORDER BY 
    fc.total_sales DESC;
