
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
        AND i.i_current_price > 0
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_sk, 
        web_site_id 
    FROM 
        RankedSales 
    WHERE 
        profit_rank <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'M') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        ca.ca_city,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ca.ca_city
),
FinalReport AS (
    SELECT 
        ci.gender,
        ci.marital_status,
        ci.ca_city,
        ci.order_count,
        ci.total_spent,
        ws.web_site_id
    FROM 
        CustomerInfo ci
    JOIN 
        TopWebSites ws ON ci.order_count > 0
    ORDER BY 
        ci.total_spent DESC, ci.order_count DESC
)
SELECT 
    *
FROM 
    FinalReport
WHERE 
    total_spent IS NOT NULL
ORDER BY 
    total_spent DESC
LIMIT 100;
