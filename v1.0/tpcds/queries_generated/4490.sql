
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.web_site_id, 
        ws.ws_sold_date_sk, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk, ws.web_site_id, ws.ws_sold_date_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_order_value,
        MAX(ws.ws_net_profit) AS max_order_value
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status
),
Returns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_amount) AS total_return_amount,
        COUNT(sr_item_sk) AS return_count
    FROM store_returns
    GROUP BY sr_returning_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_orders,
    cs.avg_order_value,
    cs.max_order_value,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.return_count, 0) AS return_count,
    rs.web_site_id,
    rs.total_net_profit
FROM CustomerStats cs
LEFT JOIN Returns r ON cs.c_customer_sk = r.sr_returning_customer_sk
JOIN RankedSales rs ON cs.total_orders > 0 AND cs.avg_order_value > 100
    AND rs.profit_rank <= 10
ORDER BY rs.total_net_profit DESC, cs.total_orders DESC;
