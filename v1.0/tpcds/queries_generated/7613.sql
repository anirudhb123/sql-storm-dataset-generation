
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND i.i_current_price > 50.00
    GROUP BY 
        ws.web_site_id
),
AverageData AS (
    SELECT 
        AVG(total_quantity) AS avg_quantity,
        AVG(total_net_profit) AS avg_net_profit,
        AVG(total_orders) AS avg_orders
    FROM 
        SalesData
)
SELECT 
    sd.web_site_id,
    sd.total_quantity,
    sd.total_net_profit,
    sd.total_orders,
    ad.avg_quantity,
    ad.avg_net_profit,
    ad.avg_orders,
    CASE 
        WHEN sd.total_quantity > ad.avg_quantity THEN 'Above Average'
        ELSE 'Below Average' 
    END AS quantity_performance,
    CASE 
        WHEN sd.total_net_profit > ad.avg_net_profit THEN 'Above Average'
        ELSE 'Below Average' 
    END AS profit_performance,
    CASE 
        WHEN sd.total_orders > ad.avg_orders THEN 'Above Average'
        ELSE 'Below Average' 
    END AS orders_performance
FROM 
    SalesData sd
CROSS JOIN 
    AverageData ad
ORDER BY 
    sd.total_net_profit DESC;
