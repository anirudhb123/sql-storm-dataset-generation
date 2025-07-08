
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_ext_sales_price) AS total_revenue
    FROM web_sales
    GROUP BY ws_sold_date_sk
    UNION ALL
    SELECT
        sd.ws_sold_date_sk,
        ss.total_sales + sd.total_sales,
        ss.total_revenue + sd.total_revenue
    FROM sales_summary ss
    JOIN (
        SELECT
            ws_sold_date_sk,
            SUM(ws_quantity) AS total_sales,
            SUM(ws_ext_sales_price) AS total_revenue
        FROM web_sales
        WHERE ws_sold_date_sk > (SELECT MIN(ws_sold_date_sk) FROM web_sales)
        GROUP BY ws_sold_date_sk
    ) sd ON ss.ws_sold_date_sk < sd.ws_sold_date_sk
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
address_summary AS (
    SELECT
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_state
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COALESCE(cs.total_spent, 0) AS total_customer_spent,
    asu.customer_count,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_sales_price) DESC) as rank
FROM warehouse w
JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
LEFT JOIN customer_summary cs ON cs.c_customer_sk = ws.ws_bill_customer_sk
JOIN address_summary asu ON asu.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = ws.ws_bill_customer_sk LIMIT 1))
GROUP BY w.w_warehouse_id, w.w_warehouse_name, cs.total_spent, asu.customer_count
HAVING SUM(ws.ws_quantity) > 100
ORDER BY total_quantity DESC, avg_sales_price ASC;
