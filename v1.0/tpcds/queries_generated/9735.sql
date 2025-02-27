
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE cd.cd_gender = 'F' 
      AND cd.cd_marital_status = 'M' 
      AND cd.cd_purchase_estimate > 500 
      AND ws.ws_sold_date_sk BETWEEN 2400 AND 2405
    GROUP BY ws.web_site_id
),
TopWebSites AS (
    SELECT web_site_id, total_orders, total_profit
    FROM RankedSales
    WHERE rank <= 10 
)
SELECT 
    w.web_site_id,
    w.web_name,
    tw.total_orders,
    tw.total_profit,
    ROUND(tw.total_profit / tw.total_orders, 2) AS avg_profit_per_order
FROM web_site w
JOIN TopWebSites tw ON w.web_site_id = tw.web_site_id
ORDER BY tw.total_profit DESC;
