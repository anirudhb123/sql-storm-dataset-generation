
WITH RECURSIVE sales_per_week AS (
    SELECT
        d.d_date,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (ORDER BY d.d_date) AS week_number
    FROM
        date_dim d
    JOIN
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE
        d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY
        d.d_date
),
weekly_sales_summary AS (
    SELECT
        week_number,
        AVG(total_sales) OVER (ORDER BY week_number ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS avg_sales_last_4_weeks,
        MAX(total_sales) AS max_sales_in_week,
        MIN(total_sales) AS min_sales_in_week
    FROM
        sales_per_week
),
customer_returns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt) AS total_returned,
        COUNT(sr_item_sk) AS total_returns
    FROM
        store_returns
    WHERE
        sr_returned_date_sk IS NOT NULL
    GROUP BY
        sr_customer_sk
)
SELECT
    c.c_customer_id,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    COALESCE(SUM(cr.total_returned), 0) AS total_web_returns,
    SUM(CASE WHEN ws.ws_sales_price > 100 THEN ws.ws_net_profit ELSE 0 END) AS high_value_profit,
    wss.avg_sales_last_4_weeks,
    wss.max_sales_in_week,
    wss.min_sales_in_week
FROM
    customer c
LEFT JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN
    customer_returns cr ON c.c_customer_sk = cr.sr_customer_sk
JOIN
    weekly_sales_summary wss ON DATE_TRUNC('week', ws.ws_sold_date) = DATE_TRUNC('week', wss.week_number)
WHERE
    c.c_birth_year BETWEEN 1980 AND 1990
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_last_review_date_sk IS NULL)
GROUP BY
    c.c_customer_id, wss.avg_sales_last_4_weeks, wss.max_sales_in_week, wss.min_sales_in_week
ORDER BY
    total_web_orders DESC, total_web_returns DESC;
