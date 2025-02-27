
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws.web_name, ws.ws_sold_date_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    r.web_name,
    r.total_profit,
    r.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    CASE 
        WHEN r.total_profit IS NULL THEN 'No Profit'
        ELSE 'Profit Generated'
    END AS profit_status
FROM 
    RankedSales r
LEFT JOIN 
    CustomerDemographics cd ON r.web_site_sk = cd.cd_demo_sk
WHERE 
    r.profit_rank <= 5
ORDER BY 
    r.total_profit DESC, cd.customer_count DESC;
