
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender_description
    FROM 
        CustomerSales c
    JOIN 
        customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_customer_sk = ca.ca_address_sk
    WHERE 
        c.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    tc.ca_city,
    tc.ca_state,
    tc.gender_description
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_sales DESC
LIMIT 10;

WITH DateSales AS (
    SELECT 
        dd.d_date AS sales_date,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ws.ws_net_paid) AS total_web_sales
    FROM 
        date_dim dd
    LEFT JOIN 
        store_sales ss ON dd.d_date_sk = ss.ss_sold_date_sk
    LEFT JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        dd.d_date
)
SELECT 
    ds.sales_date,
    ds.total_store_sales,
    ds.total_web_sales,
    COALESCE(ds.total_store_sales, 0) - COALESCE(ds.total_web_sales, 0) AS sales_difference
FROM 
    DateSales ds
WHERE 
    ds.sales_date > (CURRENT_DATE - INTERVAL '1 month')
ORDER BY 
    ds.sales_date;
