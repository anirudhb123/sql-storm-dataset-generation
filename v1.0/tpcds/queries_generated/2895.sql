
WITH RankedSales AS (
    SELECT 
        ws.customer_sk,
        SUM(ws.net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank_within_customer
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.gender,
        cd.marital_status,
        cd.education_status
    FROM 
        customer_demographics cd
    WHERE 
        cd_cd_demo_sk IN (SELECT DISTINCT c_current_cdemo_sk FROM customer WHERE c_current_cdemo_sk IS NOT NULL)
),
HighProfitCustomers AS (
    SELECT 
        r.customer_sk,
        r.total_profit,
        cd.gender,
        cd.marital_status,
        cd.education_status
    FROM 
        RankedSales r
    JOIN 
        CustomerDemographics cd ON r.customer_sk = cd.cd_demo_sk
    WHERE 
        r.rank_within_customer = 1 AND r.total_profit > 1000
)
SELECT 
    w.w_warehouse_name,
    COUNT(DISTINCT h.customer_sk) AS high_profit_customers_count,
    AVG(h.total_profit) AS avg_profit,
    STRING_AGG(CONCAT(cd.gender, ': ', COUNT(DISTINCT cd.cd_demo_sk)) ORDER BY cd.gender) AS gender_distribution
FROM 
    HighProfitCustomers h
JOIN 
    inventory i ON h.customer_sk = i.inv_item_sk
JOIN 
    warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN 
    CustomerDemographics cd ON h.customer_sk = cd.cd_demo_sk
GROUP BY 
    w.warehouse_name
HAVING 
    COUNT(DISTINCT h.customer_sk) > 5
ORDER BY 
    avg_profit DESC;
