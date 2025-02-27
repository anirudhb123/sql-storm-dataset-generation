
WITH RECURSIVE sales_cte AS (
    SELECT
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(*) AS total_transactions,
        1 AS level
    FROM
        store_sales
    GROUP BY
        ss_store_sk
    UNION ALL
    SELECT
        s.ss_store_sk,
        SUM(s.ss_ext_sales_price) + c.total_sales,
        COUNT(s.ss_ticket_number) + c.total_transactions,
        c.level + 1
    FROM
        store_sales s
    JOIN sales_cte c ON s.ss_store_sk = c.ss_store_sk
    WHERE
        c.level < 5
    GROUP BY
        s.ss_store_sk, c.total_sales, c.total_transactions, c.level
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        MAX(ws.ws_ship_date_sk) AS last_purchase_date
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_customer_sk, cd.cd_gender
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.gender,
        cs.total_web_sales,
        cs.web_orders,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS rank
    FROM
        customer_summary cs
)
SELECT 
    s.ss_store_sk AS warehouse_sk,
    s.total_sales,
    tc.gender,
    tc.total_web_sales,
    tc.web_orders,
    CASE
        WHEN tc.total_web_sales IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status
FROM 
    sales_cte s
LEFT JOIN top_customers tc ON s.ss_store_sk = tc.c_customer_sk
WHERE 
    s.total_sales > 10000 
    AND (tc.web_orders IS NULL OR tc.web_orders > 10)
ORDER BY 
    s.total_sales DESC, 
    tc.rank;
