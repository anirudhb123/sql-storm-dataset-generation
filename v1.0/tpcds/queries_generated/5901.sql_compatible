
WITH top_customers AS (
    SELECT c.c_customer_id, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    GROUP BY c.c_customer_id
    ORDER BY total_sales DESC
    LIMIT 10
),
popular_items AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity_sold
    FROM web_sales ws
    JOIN top_customers tc ON ws.ws_bill_customer_sk IN (
        SELECT c.c_customer_sk
        FROM customer c
        WHERE c.c_customer_id = tc.c_customer_id
    )
    GROUP BY ws.ws_item_sk
    ORDER BY total_quantity_sold DESC
    LIMIT 5
),
sales_by_month AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM date_dim dd
    JOIN web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY dd.d_year, dd.d_month_seq
),
average_monthly_sales AS (
    SELECT d_year, AVG(monthly_sales) AS avg_sales
    FROM sales_by_month
    GROUP BY d_year
)
SELECT 
    tm.c_customer_id,
    pi.total_quantity_sold,
    ams.avg_sales
FROM top_customers tm
JOIN popular_items pi ON tm.c_customer_id = (
    SELECT c.c_customer_id
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_item_sk = pi.ws_item_sk
    ORDER BY ws.ws_ext_sales_price DESC
    LIMIT 1
)
JOIN average_monthly_sales ams ON ams.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
ORDER BY pi.total_quantity_sold DESC, ams.avg_sales DESC;
