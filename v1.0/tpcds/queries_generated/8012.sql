
WITH RankedOrders AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        cd.cd_gender = 'F'
        AND d.d_year = 2023
    GROUP BY
        ws.web_site_id
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_net_profit,
        total_orders
    FROM 
        RankedOrders
    WHERE 
        rank <= 5
)
SELECT 
    w.warehouse_name,
    w.warehouse_city,
    SUM(ws.ws_net_sales) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    TW.total_net_profit,
    TW.total_orders
FROM 
    warehouse w
JOIN 
    web_sales ws ON w.warehouse_sk = ws.ws_warehouse_sk
JOIN 
    TopWebsites TW ON ws.ws_web_site_sk = TW.web_site_id
GROUP BY 
    w.warehouse_name, w.warehouse_city, TW.total_net_profit, TW.total_orders
ORDER BY 
    total_sales DESC
LIMIT 10;
