
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        c.c_email_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
RecentSales AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date >= CURRENT_DATE - INTERVAL '30' DAY
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
),
SalesRanking AS (
    SELECT 
        r.*, 
        RANK() OVER (PARTITION BY r.ws_item_sk ORDER BY r.total_profit DESC) AS profit_rank
    FROM 
        RecentSales r
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    sr.ws_item_sk,
    sr.total_quantity,
    sr.total_profit,
    sr.profit_rank
FROM 
    CustomerInfo ci
JOIN 
    SalesRanking sr ON ci.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = sr.ws_item_sk)
WHERE 
    sr.profit_rank <= 10
ORDER BY 
    sr.total_profit DESC, ci.full_name;
