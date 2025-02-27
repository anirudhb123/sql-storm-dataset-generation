
WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_web_site_sk,
        ws.ws_net_profit,
        1 AS level
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_net_profit IS NOT NULL

    UNION ALL

    SELECT 
        cte.c_customer_sk,
        cte.c_first_name,
        cte.c_last_name,
        ws.ws_web_site_sk,
        ws.ws_net_profit + cte.ws_net_profit,
        cte.level + 1
    FROM 
        SalesCTE cte
    JOIN 
        web_sales ws ON cte.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_net_profit IS NOT NULL AND cte.level < 5
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ws.ws_net_profit) AS avg_web_profit,
    MAX(hd.hd_dep_count) AS max_dependents,
    COALESCE(SUM(ws.ws_net_profit), 0) AS web_total_profit,
    (SELECT COUNT(*) FROM customer_demographics cd WHERE cd.cd_marital_status = 'M') AS married_count,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name)) AS customer_names
FROM 
    customer_address ca
LEFT OUTER JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
WHERE 
    (ca.ca_state = 'CA' OR ca.ca_state = 'TX')
    AND (ws.ws_net_profit > 100 OR ss.ss_net_profit > 100 OR hd.hd_buy_potential = 'High')
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT ss.ss_ticket_number) > 10
ORDER BY 
    total_profit DESC
LIMIT 10;
