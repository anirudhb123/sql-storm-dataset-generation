
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(ss.ss_ticket_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss.s_store_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS rn
    FROM
        store_sales ss
    WHERE
        ss.ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss.s_store_sk
    HAVING 
        SUM(ss.ss_net_profit) IS NOT NULL
    UNION ALL
    SELECT 
        sh.s_store_sk,
        sh.total_net_profit * 1.1 AS total_net_profit,
        sh.total_sales,
        sh.rn + 1
    FROM 
        sales_hierarchy sh
    WHERE 
        sh.total_net_profit > 3000
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN h.hd_income_band_sk IS NULL THEN 'Unknown'
            ELSE CONCAT('Income Band: ', h.hd_income_band_sk)
        END AS income_band,
        isnull(SUM(ws.ws_net_profit), 0) AS total_profit_web
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics h ON h.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, h.hd_income_band_sk
),
customer_ranks AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.income_band,
        RANK() OVER (PARTITION BY ci.cd_gender ORDER BY ci.total_profit_web DESC) AS gender_rank
    FROM 
        customer_info ci
)
SELECT 
    sh.s_store_sk,
    sh.total_net_profit,
    cr.c_customer_id,
    cr.gender_rank
FROM 
    sales_hierarchy sh
JOIN 
    customer_ranks cr ON cr.cd_purchase_estimate > 5000
WHERE 
    sh.rn <= 10
ORDER BY 
    sh.total_net_profit DESC;
