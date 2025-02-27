
WITH RECURSIVE SalesCTE AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s_store_sk
    
    UNION ALL
    
    SELECT 
        sc.s_store_sk,
        SUM(ss.net_profit) AS total_profit,
        COUNT(DISTINCT ss.ticket_number) AS total_sales
    FROM 
        SalesCTE sc
    JOIN 
        store_sales ss ON sc.s_store_sk = ss.s_store_sk
    WHERE 
        ss_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 LIMIT 1 OFFSET (SELECT COUNT(*) FROM SalesCTE))
    GROUP BY 
        sc.s_store_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'M') AS gender,
        COUNT(ws.ws_order_number) AS orders_count
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year < 1985
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
ProfitAnalysis AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS store_profit,
        AVG(ss.ss_net_profit) AS avg_profit_per_sale,
        SUM(ss.ss_quantity) as total_quantity_sold,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM 
        store AS s
    JOIN 
        store_sales AS ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ps.store_profit) AS total_store_profit,
    SUM(cs.orders_count) AS total_orders_by_age_group,
    AVG(ps.avg_profit_per_sale) AS average_profit_per_sale,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers
FROM 
    CustomerStats AS cs
JOIN 
    customer_address AS ca ON cs.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    ProfitAnalysis AS ps ON ps.s_store_id = (SELECT s_store_id FROM store WHERE s_store_sk = (SELECT MIN(s_store_sk) FROM store))
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(cs.c_customer_sk) > 0
ORDER BY 
    total_store_profit DESC, total_orders_by_age_group DESC;
