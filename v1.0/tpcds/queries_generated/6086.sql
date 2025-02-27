
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        d.d_day_name
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
        AND d.d_month_seq IN (1, 2, 3)
    GROUP BY 
        c.c_customer_id, d.d_year, d.d_month_seq, d.d_week_seq, d.d_day_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_quantity,
        cs.total_net_paid
    FROM 
        SalesSummary cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(cd.cd_gender) AS gender_count,
    AVG(cd.total_quantity) AS avg_quantity,
    SUM(cd.total_net_paid) AS total_sales
FROM 
    CustomerDemographics cd
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    gender_count DESC, total_sales DESC
LIMIT 10;
