
WITH sales_summary AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM
        customer c
    JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id
),
return_summary AS (
    SELECT
        sr.returning_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns,
        COUNT(sr.sr_order_number) AS total_returns_count
    FROM
        store_returns sr
    GROUP BY
        sr.returning_customer_sk
),
customer_analytics AS (
    SELECT
        c.c_customer_id,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        ss.total_transactions,
        (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returns, 0)) AS net_revenue
    FROM
        customer c
    LEFT JOIN
        sales_summary ss ON c.c_customer_id = ss.c_customer_id
    LEFT JOIN
        return_summary rs ON c.c_customer_sk = rs.returning_customer_sk
)

SELECT
    ca.c_customer_id,
    ca.total_sales,
    ca.total_returns,
    ca.total_transactions,
    ca.net_revenue,
    CASE
        WHEN ca.total_sales = 0 THEN 'No Sales'
        WHEN ca.net_revenue < 0 THEN 'Net Loss'
        ELSE 'Profitable'
    END AS profitability_status
FROM
    customer_analytics ca
WHERE
    ca.net_revenue > 1000
ORDER BY
    ca.total_sales DESC
FETCH FIRST 10 ROWS ONLY;

-- Outer join with more conditions
SELECT
    c.c_customer_id,
    COALESCE(COUNT(DISTINCT ws.ws_order_number), 0) AS total_web_orders,
    COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_revenue
FROM
    customer c
LEFT JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE
    c.c_birth_country IS NOT NULL
GROUP BY
    c.c_customer_id
HAVING
    total_web_revenue > 5000
ORDER BY
    total_web_revenue DESC;
