
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS ranking
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
SalesDetails AS (
    SELECT 
        sh.c_customer_id,
        sh.total_profit,
        d.d_year,
        d.d_quarter_seq,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_revenue
    FROM SalesHierarchy sh
    JOIN date_dim d ON d.d_date_sk IN (
        SELECT DISTINCT ws.ws_sold_date_sk
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = sh.c_customer_sk
    )
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = sh.c_customer_sk
    GROUP BY sh.c_customer_id, sh.total_profit, d.d_year, d.d_quarter_seq
),
TopSales AS (
    SELECT 
        customer_id,
        total_profit,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS top_rank
    FROM SalesHierarchy
    WHERE total_profit IS NOT NULL
)
SELECT 
    sd.customer_id,
    sd.total_profit,
    sd.total_quantity,
    sd.total_revenue,
    CASE 
        WHEN sd.total_quantity > 100 THEN 'High Volume'
        WHEN sd.total_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    CASE 
        WHEN sd.total_revenue > 1000 THEN 'Profitable'
        WHEN sd.total_revenue BETWEEN 500 AND 1000 THEN 'Moderately Profitable'
        ELSE 'Less Profitable'
    END AS profitability_category,
    th.top_rank
FROM SalesDetails sd
LEFT JOIN TopSales th ON sd.customer_id = th.customer_id
WHERE sd.total_profit > (SELECT AVG(total_profit) FROM SalesHierarchy)
ORDER BY sd.total_profit DESC, sd.customer_id
LIMIT 100;
