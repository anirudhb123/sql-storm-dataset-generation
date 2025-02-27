
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank,
        ws.ws_net_paid,
        COALESCE(NULLIF(ws.ws_net_paid_inc_tax, 0), 1) AS adjusted_net_paid,
        CASE 
            WHEN ws.ws_net_paid > 100 THEN 'High'
            WHEN ws.ws_net_paid BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low' 
        END AS sales_category
    FROM web_sales ws
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_current_addr_sk IS NOT NULL
),
sales_with_promotions AS (
    SELECT 
        rs.sales_rank,
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_net_paid,
        ps.p_discount_active,
        rs.sales_category,
        CASE 
            WHEN ps.p_discount_active = 'Y' THEN ROUND((rs.ws_net_paid * 0.1), 2)
            ELSE 0
        END AS discount_amount
    FROM ranked_sales rs
    LEFT JOIN promotion ps ON ps.p_item_sk = rs.ws_item_sk
    WHERE rs.sales_rank <= 3
),
total_discounted_sales AS (
    SELECT 
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(s.discount_amount) AS total_discounts
    FROM web_sales ws
    JOIN sales_with_promotions s ON ws.ws_order_number = s.ws_order_number
    WHERE ws.ws_net_paid > 0
),
final_output AS (
    SELECT 
        ts.total_sales,
        ts.total_discounts,
        (ts.total_sales - ts.total_discounts) AS net_sales,
        CASE 
            WHEN ts.total_sales IS NULL OR ts.total_discounts IS NULL THEN 'No Data'
            ELSE CAST((ts.total_discounts / NULLIF(ts.total_sales, 0)) * 100 AS DECIMAL(5,2)) || '%' 
        END AS discount_percentage
    FROM total_discounted_sales ts
)
SELECT 
    fo.total_sales, 
    fo.total_discounts,
    fo.net_sales,
    fo.discount_percentage
FROM final_output fo
WHERE fo.net_sales > 200
UNION ALL
SELECT
    'Aggregate Statistics',
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_net_paid) AS average_net_paid,
    MAX(ws.ws_net_paid) AS max_net_paid
FROM web_sales ws
WHERE ws.ws_net_paid IS NOT NULL
HAVING MAX(ws.ws_net_paid) < 1000;
