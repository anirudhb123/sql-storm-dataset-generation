
WITH RankedSales AS (
    SELECT 
        coalesce(ws.bill_customer_sk, ss.customer_sk) AS customer_sk,
        d.d_year,
        SUM(COALESCE(ws.net_profit, 0) + COALESCE(ss.net_profit, 0)) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(COALESCE(ws.net_profit, 0) + COALESCE(ss.net_profit, 0)) DESC) AS profit_rank
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_order_number
    JOIN 
        date_dim d ON d.d_date_sk = COALESCE(ws.ws_sold_date_sk, ss.ss_sold_date_sk)
    GROUP BY 
        customer_sk, d.d_year
),
HighProfitCustomers AS (
    SELECT 
        customer_sk,
        d_year,
        total_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    hpc.customer_sk,
    SUM(hpc.total_profit) AS overall_profit,
    COUNT(DISTINCT dem.c_customer_sk) AS unique_customers,
    STRING_AGG(CONCAT(dem.cd_gender, ': ', COALESCE(dem.cd_marital_status, 'Unknown')), ', ') AS demographics_info
FROM 
    HighProfitCustomers hpc
LEFT JOIN 
    CustomerDemographics dem ON hpc.customer_sk = dem.c_customer_sk
GROUP BY 
    hpc.customer_sk
HAVING 
    COUNT(DISTINCT dem.c_customer_sk) > 0 OR overall_profit > 1000
ORDER BY 
    overall_profit DESC
LIMIT 50;
