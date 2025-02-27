
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    AND cd.cd_marital_status = 'M'
    AND w.web_marital_status = 'M'
    GROUP BY ws.web_site_id, d.d_year
),
TopSales AS (
    SELECT 
        web_site_id,
        d_year,
        total_net_profit,
        total_orders,
        total_quantity,
        RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
    FROM SalesSummary
)
SELECT 
    t.web_site_id,
    t.d_year,
    t.total_net_profit,
    t.total_orders,
    t.total_quantity
FROM TopSales t
WHERE t.profit_rank <= 10
ORDER BY t.d_year, t.total_net_profit DESC;
