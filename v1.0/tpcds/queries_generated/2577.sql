
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
),
SalesWithDemographics AS (
    SELECT 
        tc.first_name,
        tc.last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 500 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1500 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_segment,
        tc.total_sales
    FROM 
        TopCustomers tc
    LEFT JOIN 
        customer_demographics cd ON tc.customer_sk = cd.cd_demo_sk
)
SELECT 
    swd.first_name,
    swd.last_name,
    swd.gender,
    swd.marital_status,
    swd.purchase_estimate_segment,
    swd.total_sales,
    RANK() OVER (PARTITION BY swd.purchase_estimate_segment ORDER BY swd.total_sales DESC) AS segment_rank
FROM 
    SalesWithDemographics swd
ORDER BY 
    swd.total_sales DESC;
