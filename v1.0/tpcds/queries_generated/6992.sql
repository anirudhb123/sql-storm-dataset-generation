
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id
), TopWebSites AS (
    SELECT 
        web_site_id, 
        total_net_profit, 
        order_count
    FROM 
        RankedSales
    WHERE 
        rn <= 5
)
SELECT 
    tw.web_site_id,
    tw.total_net_profit,
    tw.order_count,
    ca.city AS warehouse_city,
    ca.state AS warehouse_state
FROM 
    TopWebSites tw
JOIN 
    warehouse w ON w.w_warehouse_id = tw.web_site_id
JOIN 
    customer_address ca ON w.w_warehouse_sk = ca.ca_address_sk
ORDER BY 
    tw.total_net_profit DESC;
