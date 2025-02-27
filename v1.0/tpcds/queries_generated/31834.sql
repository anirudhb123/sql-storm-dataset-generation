
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.cd_marital_status,
        ch.hd_income_band_sk
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON ch.c_customer_sk = c.c_current_cdemo_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS married_customers,
    AVG(hd.hd_income_band_sk) AS avg_income_band,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_sales_profit,
    SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_sales_profit
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    CustomerHierarchy ch ON c.c_customer_sk = ch.c_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    household_demographics hd ON ch.hd_income_band_sk = hd.hd_income_band_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 0
ORDER BY 
    total_web_sales_profit DESC NULLS LAST;
