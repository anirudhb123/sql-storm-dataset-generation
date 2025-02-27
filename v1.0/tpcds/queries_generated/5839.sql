
WITH MonthlySales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_month_seq
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesWithDemographics AS (
    SELECT 
        md.d_month_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(md.total_sales) AS total_sales
    FROM 
        MonthlySales md
    JOIN 
        web_sales ws ON md.total_orders = COUNT(DISTINCT ws.ws_order_number)
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        md.d_month_seq, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    d.d_month_seq,
    STRING_AGG(CONCAT(cd.cd_gender, ' - ', cd.cd_marital_status), ', ') AS demographic_info,
    SUM(swd.total_sales) AS total_sales_by_demographics
FROM 
    SalesWithDemographics swd
JOIN 
    date_dim d ON swd.d_month_seq = d.d_month_seq
GROUP BY 
    d.d_month_seq
ORDER BY 
    d.d_month_seq;
