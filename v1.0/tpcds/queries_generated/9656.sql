
WITH MonthlySales AS (
    SELECT 
        dd.d_month_seq AS month,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_month_seq
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(ms.total_sales) AS total_sales_per_demographic
    FROM 
        MonthlySales ms
    JOIN 
        customer c ON ms.month = EXTRACT(MONTH FROM CURRENT_DATE)
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
TopDemographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.total_sales_per_demographic
    FROM 
        CustomerDemographics cd
    ORDER BY 
        cd.total_sales_per_demographic DESC
    LIMIT 5
)
SELECT 
    td.cd_gender,
    td.cd_marital_status,
    td.total_sales_per_demographic,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM 
    TopDemographics td
JOIN 
    customer c ON (td.cd_gender = c.c_gender AND td.cd_marital_status = c.c_marital_status)
GROUP BY 
    td.cd_gender, td.cd_marital_status, td.total_sales_per_demographic
ORDER BY 
    td.total_sales_per_demographic DESC;
