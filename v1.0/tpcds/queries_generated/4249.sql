
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws_ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1960 AND 1990
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        COUNT(hd.hd_demo_sk) AS household_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.gender,
    cd.marital_status,
    COUNT(DISTINCT rs.bill_customer_sk) AS high_value_customers,
    SUM(rs.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_net_paid_inc_tax) AS total_paid_inc_tax
FROM 
    customer c 
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.bill_customer_sk
JOIN 
    store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
WHERE 
    rs.sales_rank <= 10
    AND ss.ss_sold_date_sk BETWEEN 
        (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY 
    c.c_first_name, c.c_last_name, cd.gender, cd.marital_status
HAVING 
    total_net_profit > 10000 
ORDER BY 
    total_net_profit DESC
LIMIT 50;
