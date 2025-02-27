
WITH RankedSales AS (
    SELECT
        ws.web_site_sk, 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_current_addr_sk IS NOT NULL
),
TopSales AS (
    SELECT
        rs.web_site_sk,
        SUM(rs.ws_net_profit) AS total_profit
    FROM RankedSales rs
    WHERE rs.rank <= 10
    GROUP BY rs.web_site_sk
),
SalesWithDetails AS (
    SELECT
        ts.web_site_sk,
        ts.total_profit,
        w.w_warehouse_name,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM TopSales ts
    JOIN warehouse w ON ts.web_site_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ts.web_site_sk = ws.ws_web_site_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY ts.web_site_sk, w.w_warehouse_name, ts.total_profit
)
SELECT 
    swd.web_site_sk,
    swd.w_warehouse_name,
    swd.total_profit,
    swd.unique_customers,
    swd.avg_sales_price,
    COALESCE(ROUND((swd.total_profit / NULLIF(swd.unique_customers, 0)), 2), 0) AS profit_per_customer,
    CASE 
        WHEN swd.total_profit > 100000 THEN 'High'
        WHEN swd.total_profit BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM SalesWithDetails swd
ORDER BY swd.total_profit DESC;
