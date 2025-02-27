
WITH RECURSIVE income_bracket AS (
    SELECT ib_income_band_sk, ab_lower_bound, ab_upper_bound
    FROM income_band
    WHERE ib_lower_bound < 50000
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_bracket ibr ON ibr.ib_income_band_sk + 1 = ib.ib_income_band_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
sales_with_bracket AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE 
            WHEN cs.total_sales IS NULL THEN 'No Sales'
            WHEN cs.total_sales < ib.ib_lower_bound THEN 'Below Income Band'
            WHEN cs.total_sales BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound THEN 'Within Income Band'
            ELSE 'Above Income Band'
        END AS income_status
    FROM customer_sales cs
    LEFT JOIN income_band ib ON cs.total_sales >= ib.ib_lower_bound
)
SELECT 
    s.c_customer_id,
    s.total_sales,
    s.income_status,
    COUNT(DISTINCT r.sr_item_sk) AS returns_count,
    MAX(COALESCE(ws.ws_ext_discount_amt, 0)) AS max_discount,
    STRING_AGG(DISTINCT CONCAT(s.c_customer_id, '/', s.income_status), ', ') WITHIN GROUP (ORDER BY s.c_customer_id) AS summary_group
FROM sales_with_bracket s
LEFT JOIN store_returns r ON s.c_customer_id = r.sr_customer_sk
GROUP BY s.c_customer_id, s.total_sales, s.income_status
HAVING COUNT(DISTINCT r.sr_item_sk) > 0 OR s.total_sales IS NULL
ORDER BY s.total_sales DESC, s.c_customer_id;
