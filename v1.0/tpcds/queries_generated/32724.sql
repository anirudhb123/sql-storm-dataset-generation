
WITH RECURSIVE sales_growth AS (
    SELECT
        ws.bill_customer_sk,
        ws.sold_date_sk,
        SUM(ws.net_profit) AS total_profit,
        1 AS year_level
    FROM web_sales ws
    JOIN date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
    GROUP BY ws.bill_customer_sk, ws.sold_date_sk
    UNION ALL
    SELECT
        sg.bill_customer_sk,
        sg.sold_date_sk,
        SUM(ws.net_profit) AS total_profit,
        year_level + 1
    FROM sales_growth sg
    JOIN web_sales ws ON sg.bill_customer_sk = ws.bill_customer_sk
    JOIN date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE d.d_year = YEAR(d.d_date) - year_level
    GROUP BY sg.bill_customer_sk, sg.sold_date_sk
),
seasonal_avg AS (
    SELECT
        d.d_month,
        AVG(ws.net_profit) AS avg_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.sold_date_sk = d.d_date_sk
    GROUP BY d.d_month
),
customer_analysis AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cd.cd_gender, 'Not Specified') AS gender,
        SUM(ws.net_profit) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.net_profit) DESC) AS sales_rank,
        CASE 
            WHEN COUNT(ws.ws_order_number) > 10 THEN 'Frequent'
            WHEN COUNT(ws.ws_order_number) BETWEEN 3 AND 10 THEN 'Occasional'
            ELSE 'Rare'
        END AS customer_type
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender
),
top_customers AS (
    SELECT 
        ca.c_customer_id,
        ca.gender,
        ca.total_sales,
        ca.total_orders,
        ca.customer_type,
        RANK() OVER (ORDER BY ca.total_sales DESC) AS sales_rank
    FROM customer_analysis ca
    WHERE ca.total_sales > (
        SELECT AVG(total_sales) FROM customer_analysis
    )
)
SELECT 
    tc.c_customer_id,
    tc.gender,
    tc.total_sales,
    tc.total_orders,
    tc.customer_type,
    sg.total_profit AS growth_profit,
    sa.avg_profit AS seasonal_avg_profit
FROM top_customers tc
LEFT JOIN sales_growth sg ON tc.c_customer_id = sg.bill_customer_sk
LEFT JOIN seasonal_avg sa ON MONTH(sg.sold_date_sk) = sa.d_month
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC, tc.customer_id;
