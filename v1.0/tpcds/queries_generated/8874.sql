
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        d.d_year
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        d.d_year
    HAVING 
        SUM(ws.ws_net_paid) > 1000
), TopCustomers AS (
    SELECT 
        c_customer_id, 
        total_sales, 
        order_count, 
        avg_order_value, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    YEAR, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    COUNT(c_customer_id) AS customer_count,
    SUM(total_sales) AS total_sales_amount,
    AVG(avg_order_value) AS avg_order_value,
    MAX(total_sales) AS max_sales
FROM 
    (SELECT 
        d.d_year AS YEAR, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        total_sales
    FROM 
        TopCustomers
    JOIN 
        date_dim d ON d.d_year = d.d_year
    WHERE 
        sales_rank <= 10
    ) AS RankedSales
GROUP BY 
    YEAR, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status
ORDER BY 
    YEAR, 
    total_sales_amount DESC;
