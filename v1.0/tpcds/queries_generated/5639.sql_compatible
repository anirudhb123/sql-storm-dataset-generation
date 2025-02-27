
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_purchase_estimate > 1000
        AND w.web_open_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_id, ws.ws_order_number
),
TopSales AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        rank <= 10
)
SELECT 
    web_site_id,
    SUM(total_quantity) AS total_quantity_sold,
    AVG(total_net_profit) AS average_net_profit
FROM 
    TopSales
GROUP BY 
    web_site_id
ORDER BY 
    total_quantity_sold DESC;
