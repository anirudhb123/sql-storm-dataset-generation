
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
TopWebsites AS (
    SELECT 
        web_site_id 
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 5
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    AVG(cd.total_spent) AS avg_spent
FROM 
    CustomerDemographics cd
JOIN 
    customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
WHERE 
    EXISTS (
        SELECT 1 
        FROM TopWebsites tw 
        JOIN web_sales ws ON tw.web_site_id = ws.ws_web_site_sk
        WHERE 
            ws.ws_bill_customer_sk = c.c_customer_sk 
    )
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    avg_spent DESC;
