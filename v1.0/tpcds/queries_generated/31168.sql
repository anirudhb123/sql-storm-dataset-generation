
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY ws.web_site_sk, ws.web_name
), CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING SUM(ws.ws_net_paid) IS NOT NULL
), TopSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM CustomerStats cs
    WHERE cs.order_count > (SELECT AVG(order_count) FROM CustomerStats)
), DailySales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_paid_inc_tax) AS daily_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
    HAVING d.d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
)
SELECT 
    w.web_name,
    sh.total_sales,
    sh.sales_rank,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    ts.total_spent,
    ts.spending_rank,
    ds.daily_sales,
    ds.total_orders
FROM SalesHierarchy sh
JOIN web_site w ON sh.web_site_sk = w.web_site_sk
LEFT JOIN TopSales ts ON ts.c_customer_sk = sh.web_site_sk
LEFT JOIN CustomerStats cs ON cs.total_spent > 1000 AND cs.c_customer_sk = sh.web_site_sk
JOIN DailySales ds ON ds.total_orders > 0
ORDER BY sh.total_sales DESC, ts.spending_rank
LIMIT 100;
