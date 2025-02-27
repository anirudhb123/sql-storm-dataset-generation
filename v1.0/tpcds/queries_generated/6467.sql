
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND ws.ws_net_profit > 0
),
TopSales AS (
    SELECT 
        rs.web_site_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_profit <= 10
    GROUP BY 
        rs.web_site_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    si.web_site_sk,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers,
    SUM(ts.total_quantity) AS total_quantity_sold,
    SUM(ts.total_net_profit) AS total_net_profit
FROM 
    TopSales ts
JOIN 
    web_site si ON ts.web_site_sk = si.web_site_sk
JOIN 
    CustomerInfo ci ON ts.web_site_sk IN (SELECT ws.ws_web_site_sk FROM web_sales ws WHERE ws.ws_order_number = ci.c_customer_sk)
GROUP BY 
    si.web_site_sk
ORDER BY 
    total_net_profit DESC;
