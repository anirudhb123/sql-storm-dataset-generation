
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
top_websites AS (
    SELECT 
        r.web_site_id,
        r.total_net_profit
    FROM 
        ranked_sales r
    WHERE 
        r.rank = 1
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
return_info AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
final_report AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        COALESCE(ri.total_return_amount, 0) AS total_return_amount,
        tw.total_net_profit
    FROM 
        customer_info ci
    LEFT JOIN 
        return_info ri ON ci.c_customer_sk = ri.sr_customer_sk
    LEFT JOIN 
        top_websites tw ON 1 = 1 -- Cartesian join to get each customer with each top website
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.cd_purchase_estimate,
    fr.total_return_amount,
    fr.total_net_profit,
    CASE 
        WHEN fr.total_return_amount > fr.total_net_profit THEN 'Profitable'
        ELSE 'Unprofitable'
    END AS profitability_status
FROM 
    final_report fr
WHERE 
    fr.cd_purchase_estimate IS NOT NULL
ORDER BY 
    fr.total_net_profit DESC, fr.c_last_name, fr.c_first_name;
