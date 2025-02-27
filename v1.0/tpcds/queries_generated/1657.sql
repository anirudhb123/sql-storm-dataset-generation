
WITH SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(DISTINCT ws.order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        ws.bill_customer_sk
),
CustomerStats AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cd.cd_gender = 'F'
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    COALESCE(sd.bill_customer_sk, cs.cd_demo_sk) AS customer_id,
    COALESCE(sd.total_profit, 0) AS total_profit,
    COALESCE(sd.order_count, 0) AS order_count,
    cs.cd_gender,
    cs.max_purchase_estimate,
    cs.customer_count
FROM 
    SalesData sd
FULL OUTER JOIN 
    CustomerStats cs ON sd.bill_customer_sk = cs.cd_demo_sk
WHERE 
    (sd.total_profit > 500 OR cs.cd_marital_status = 'M')
ORDER BY 
    total_profit DESC, customer_count DESC;
