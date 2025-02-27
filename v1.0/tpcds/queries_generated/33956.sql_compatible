
WITH RECURSIVE sales_rank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ca.ca_country ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_country
), 
address_stats AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_country
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.total_profit,
    a.customer_count,
    a.avg_purchase_estimate
FROM 
    sales_rank r
JOIN 
    address_stats a ON a.ca_country = (SELECT ca.ca_country FROM customer_address ca WHERE ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = r.c_customer_sk))
WHERE 
    r.rank <= 10 AND a.customer_count > 100
ORDER BY 
    r.total_profit DESC;
