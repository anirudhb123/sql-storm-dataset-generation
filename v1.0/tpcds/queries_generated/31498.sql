
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        s_store_sk,
        s_store_name,
        1 AS level,
        s_store_sk AS parent_store_sk
    FROM
        store
    WHERE
        s_division_id = 1
    UNION ALL
    SELECT
        s_store_sk,
        s_store_name,
        sh.level + 1 AS level,
        sh.parent_store_sk
    FROM
        store s
    INNER JOIN sales_hierarchy sh ON s.s_division_id = sh.level
    WHERE
        s.s_closed_date_sk IS NULL
),
sales_summary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 2000 
        AND (ws.ws_net_profit > 0 OR ws.ws_net_paid_inc_tax > 100)
    GROUP BY
        ws.ws_item_sk
),
out_of_stock AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand
    FROM
        inventory inv
    WHERE
        inv.inv_quantity_on_hand = 0
),
final_report AS (
    SELECT
        ss.ws_item_sk,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_orders, 0) AS total_orders,
        CASE WHEN o.inv_item_sk IS NOT NULL THEN 'Out of Stock' END AS stock_status
    FROM
        sales_summary s
    FULL OUTER JOIN out_of_stock o ON s.ws_item_sk = o.inv_item_sk
)
SELECT
    f.ws_item_sk,
    f.total_sales,
    f.total_orders,
    f.stock_status,
    DATEADD(day, -30, CURRENT_DATE) AS last_30_days_threshold
FROM
    final_report f
WHERE
    (f.total_sales > 5000 OR f.stock_status IS NOT NULL)
ORDER BY
    f.total_sales DESC,
    f.total_orders ASC
LIMIT 10;
