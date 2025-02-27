
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND (dd.d_dow = 5 OR dd.d_dow = 6) -- weekends in 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        (
            SELECT COUNT(DISTINCT wr.wr_order_number)
            FROM web_returns wr
            WHERE wr.wr_returning_customer_sk = c.c_customer_sk
        ) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(ss.ss_ticket_number) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ca.ca_city,
    cs.total_net_profit AS total_sales_profit,
    cc.c_first_name,
    cc.c_last_name,
    cc.cd_gender,
    coalesce(SUM(NULLIF(ss.ss_net_profit,0)), 0) AS store_profit,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN  
    SalesCTE cs ON cs.web_site_sk = c.c_current_cdemo_sk
LEFT JOIN 
    CustomerCTE cc ON cc.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN 
    store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
GROUP BY 
    ca.ca_city, cs.total_net_profit, cc.c_first_name, cc.c_last_name, cc.cd_gender
HAVING 
    cs.total_net_profit > 50000
ORDER BY 
    total_sales_profit DESC
LIMIT 10;
