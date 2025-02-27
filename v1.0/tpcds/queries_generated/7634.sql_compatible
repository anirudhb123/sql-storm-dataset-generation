
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM web_sales AS ws
    JOIN customer AS c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics AS cd ON c.current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim AS d ON ws_sold_date_sk = d.d_date_sk
    WHERE cd.cd_gender = 'F'
      AND d.d_year BETWEEN 2020 AND 2022
    GROUP BY ws.web_site_sk, ws_sold_date_sk
),
TopWebsites AS (
    SELECT 
        web_site_sk,
        total_orders,
        total_profit
    FROM RankedSales
    WHERE profit_rank <= 5
)
SELECT 
    w.web_site_id,
    SUM(t.total_orders) AS orders,
    SUM(t.total_profit) AS profit,
    AVG(t.total_profit) AS avg_profit,
    COUNT(t.web_site_sk) AS num_top_websites
FROM TopWebsites AS t
JOIN web_site AS w ON t.web_site_sk = w.web_site_sk
GROUP BY w.web_site_id
ORDER BY profit DESC
LIMIT 10;
