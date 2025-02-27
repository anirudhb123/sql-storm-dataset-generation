
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_birth_year IS NOT NULL
    UNION ALL
    SELECT 
        cc.c_customer_sk,
        cc.c_first_name,
        cc.c_last_name,
        cc.c_birth_year,
        ch.level + 1
    FROM 
        customer cc
    JOIN 
        CustomerHierarchy ch ON cc.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL 
    ORDER BY 
        ws.ws_net_profit DESC
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.c_customer_sk,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cs.c_customer_sk
),
FinalResults AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(CASE WHEN cs.total_profit > 1000 THEN cs.total_profit ELSE 0 END) AS high_profit_total,
        COUNT(cs.c_customer_sk) AS total_sales_count
    FROM 
        CustomerHierarchy ch
    LEFT JOIN 
        CustomerDemographics cd ON ch.c_customer_sk = cd.c_customer_sk
    LEFT JOIN 
        SalesData cs ON ch.c_customer_sk = cs.ws_order_number 
    GROUP BY 
        ch.c_customer_sk, ch.c_first_name, ch.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.high_profit_total,
    fr.total_sales_count,
    ROW_NUMBER() OVER (ORDER BY fr.high_profit_total DESC) AS rank
FROM 
    FinalResults fr
WHERE 
    fr.high_profit_total IS NOT NULL
ORDER BY 
    fr.high_profit_total DESC
LIMIT 100;
