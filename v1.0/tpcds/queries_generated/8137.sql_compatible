
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(co.total_quantity) AS total_quantity,
        SUM(co.total_spent) AS total_spent
    FROM 
        CustomerOrders co
    JOIN 
        customer_demographics cd ON co.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
DemographicStats AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        AVG(cd.total_quantity) AS avg_quantity,
        AVG(cd.total_spent) AS avg_spent,
        COUNT(*) AS demographic_count
    FROM 
        CustomerDemographics cd
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status,
    ds.avg_quantity,
    ds.avg_spent,
    ds.demographic_count,
    CASE 
        WHEN ds.avg_spent > 1000 THEN 'High Spend'
        WHEN ds.avg_spent BETWEEN 500 AND 1000 THEN 'Medium Spend'
        ELSE 'Low Spend' 
    END AS spend_category
FROM 
    DemographicStats ds
ORDER BY 
    ds.avg_spent DESC;
