
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales AS ws
    JOIN 
        web_site AS w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SitePerformance AS (
    SELECT 
        rp.web_site_id,
        rp.total_orders,
        rp.total_profit,
        rp.avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY rp.total_profit DESC) AS gender_rank
    FROM 
        RankedSales AS rp
    LEFT JOIN 
        CustomerDemographics AS cd ON rp.web_site_id IN (SELECT ws.web_site_id FROM web_sales ws WHERE ws.ws_bill_customer_sk = cd.c_customer_sk)
)
SELECT 
    sp.web_site_id,
    sp.total_orders,
    sp.total_profit,
    sp.avg_order_value,
    sp.cd_gender,
    sp.cd_marital_status,
    sp.cd_education_status
FROM 
    SitePerformance AS sp
WHERE 
    sp.gender_rank <= 3
ORDER BY 
    sp.total_profit DESC;
