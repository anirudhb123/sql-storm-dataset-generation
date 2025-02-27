
WITH recursive customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales + COALESCE(SUM(ss.ss_net_paid), 0),
        cs.order_count + COUNT(DISTINCT ss.ss_ticket_number)
    FROM
        customer_sales cs
    LEFT JOIN store_sales ss ON cs.c_customer_sk = ss.ss_customer_sk
    GROUP BY cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.total_sales
),
income_bracket AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        (ib.ib_lower_bound + ib.ib_upper_bound) / 2 AS average_income
    FROM
        household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.order_count,
    ib.average_income,
    ROW_NUMBER() OVER (PARTITION BY ib.average_income ORDER BY cs.total_sales DESC) AS rank,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM
    customer_sales cs
LEFT JOIN income_bracket ib ON cs.c_customer_sk = ib.hd_demo_sk
WHERE 
    cs.order_count > 5 
    OR (ib.average_income IS NOT NULL AND ib.average_income > 60000)
ORDER BY 
    sales_status DESC, cs.total_sales DESC;

