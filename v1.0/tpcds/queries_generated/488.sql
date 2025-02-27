
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
        AND ws.ws_sold_date_sk IN (SELECT d_date_sk 
                                    FROM date_dim 
                                    WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6)
    GROUP BY 
        ws.web_site_id, ws.web_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cd.cd_purchase_estimate) AS average_estimate
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    r.web_site_id,
    r.web_name,
    r.total_profit,
    r.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.average_estimate
FROM 
    RankedSales r
LEFT JOIN 
    CustomerDemographics cd ON r.rank_profit = 1
WHERE 
    r.total_profit IS NOT NULL
ORDER BY 
    r.total_profit DESC
LIMIT 10
UNION ALL
SELECT 
    'Total' AS web_site_id,
    NULL AS web_name,
    SUM(total_profit) AS total_profit,
    NULL AS total_orders,
    NULL AS cd_gender,
    NULL AS cd_marital_status,
    NULL AS average_estimate
FROM 
    RankedSales;
