
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr_order_number) AS return_order_count,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_quantity) DESC) AS rn
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        COALESCE(SUM(ws.net_profit), 0) AS total_net_profit,
        COALESCE(ca.ca_city, 'Unknown') AS city,
        CUBE(cd.cd_marital_status, cd.cd_education_status) AS marital_education
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, ca.ca_city
),
FinalBenchmark AS (
    SELECT 
        cs.c_customer_id,
        cs.city,
        cs.total_net_profit,
        COALESCE(rr.total_returned, 0) AS returns,
        CASE 
            WHEN cs.marital_education IS NULL THEN 'No Stats'
            ELSE cs.marital_education
        END AS marital_education,
        CASE 
            WHEN cs.total_net_profit > 1000 THEN 'High'
            WHEN cs.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS profitability_category
    FROM 
        CustomerStats cs
    LEFT JOIN 
        RankedReturns rr ON cs.c_customer_sk = rr.wr_returning_customer_sk
)
SELECT *
FROM FinalBenchmark
WHERE 
    (returns > 5 AND profitability_category = 'Low') 
    OR (returns IS NULL AND city IN (SELECT DISTINCT ca_city FROM customer_address WHERE ca_state = 'CA'))
ORDER BY 
    total_net_profit DESC, 
    c_customer_id;
