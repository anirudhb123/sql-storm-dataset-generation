
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS dep_employed,
        COALESCE(cd.cd_dep_college_count, 0) AS dep_college
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS ranking
    FROM 
        web_sales AS ws
    UNION ALL
    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        DENSE_RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_net_profit DESC) AS ranking
    FROM 
        catalog_sales AS cs
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.dep_count,
    SUM(CASE WHEN si.ranking = 1 THEN si.ws_net_profit ELSE 0 END) AS top_profit,
    SUM(CASE WHEN si.ranking > 1 THEN si.ws_net_profit ELSE 0 END) AS other_profit
FROM 
    customer_info AS ci
LEFT JOIN 
    sales_info AS si ON ci.c_customer_sk = si.ws_bill_customer_sk
GROUP BY 
    ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status, ci.dep_count
HAVING 
    SUM(si.ws_net_profit) > 1000
ORDER BY 
    top_profit DESC, other_profit ASC
FETCH FIRST 100 ROWS ONLY;
