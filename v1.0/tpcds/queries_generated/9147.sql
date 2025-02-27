
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender, 
        cd.cd_marital_status
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023) 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
HighValueCustomers AS (
    SELECT 
        c.customer_id, 
        total_sales, 
        order_count, 
        cd_gender, 
        cd_marital_status 
    FROM 
        CustomerSales
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
SalesByGender AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS customer_count, 
        SUM(total_sales) AS gender_sales
    FROM 
        HighValueCustomers
    GROUP BY 
        cd_gender
),
SalesByMaritalStatus AS (
    SELECT 
        cd_marital_status, 
        COUNT(*) AS customer_count, 
        SUM(total_sales) AS marital_sales
    FROM 
        HighValueCustomers
    GROUP BY 
        cd_marital_status
)
SELECT 
    g.cd_gender, 
    g.customer_count AS gender_customer_count, 
    g.gender_sales,
    m.cd_marital_status, 
    m.customer_count AS marital_customer_count,
    m.marital_sales
FROM 
    SalesByGender AS g
JOIN 
    SalesByMaritalStatus AS m ON 1 = 1
ORDER BY 
    g.gender_sales DESC, 
    m.marital_sales DESC;
