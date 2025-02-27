
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE i.i_current_price > 0 AND c.c_preferred_cust_flag = 'Y'
    GROUP BY ws.web_site_sk
),
TopWebsites AS (
    SELECT 
        w.warehouse_sk,
        w.warehouse_name,
        rs.total_orders,
        rs.total_profit
    FROM warehouse w
    LEFT JOIN RankedSales rs ON w.warehouse_sk = rs.web_site_sk
    WHERE rs.total_orders IS NOT NULL AND rs.total_profit > 10000
),
CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.net_paid_inc_ship) AS total_spend,
        COUNT(ws.order_number) AS order_count,
        AVG(ws.net_profit) AS avg_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year < 1990 
    GROUP BY c.c_customer_sk
)
SELECT 
    tw.warehouse_name,
    cs.total_spend,
    cs.order_count,
    cs.avg_profit,
    COALESCE(NULLIF(cs.total_spend, 0), cs.order_count) AS adjusted_spend,
    CASE 
        WHEN cs.avg_profit > 50 THEN 'High Value'
        ELSE 'Regular Value'
    END AS customer_value_category
FROM TopWebsites tw
JOIN CustomerSpend cs ON tw.warehouse_sk = cs.c_customer_sk
ORDER BY tw.total_profit DESC, cs.total_spend DESC;
