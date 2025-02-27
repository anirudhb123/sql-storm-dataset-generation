
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 2451518 AND 2451548 -- example date range
), 
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(AVG(CASE WHEN cd.cd_dep_count IS NULL THEN 0 ELSE cd.cd_dep_count END), 0) AS avg_dep_count,
        COALESCE(AVG(CASE WHEN cd.cd_purchase_estimate IS NULL THEN 0 ELSE cd.cd_purchase_estimate END), 0) AS avg_purchase_estimate
    FROM 
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT
    ci.c_customer_sk,
    ci.c_first_name || ' ' || ci.c_last_name AS full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    (SELECT COUNT(*) FROM store s WHERE s.s_state = 'CA') AS store_count_in_CA,
    CASE 
        WHEN ci.avg_dep_count > 2 THEN 'High Dependency'
        WHEN ci.avg_dep_count <= 2 AND ci.avg_dep_count > 0 THEN 'Medium Dependency'
        ELSE 'No Dependency'
    END AS dependency_band,
    COALESCE(r.rank, 0) AS top_price_rank
FROM 
    customer_info ci
LEFT JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    ranked_sales r ON ws.ws_web_site_sk = r.web_site_sk AND r.rank = 1 
WHERE 
    r.web_site_sk IS NOT NULL AND
    SUM(ws.ws_net_profit) > 1000
GROUP BY 
    ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status, r.rank
ORDER BY 
    total_net_profit DESC;
