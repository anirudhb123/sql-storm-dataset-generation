
WITH SalesSummary AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(ws.order_number) AS total_orders,
        AVG(ws.ext_sales_price) AS avg_order_value
    FROM web_sales ws
    WHERE ws.sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY ws.bill_customer_sk
),
TopCustomers AS (
    SELECT
        css.bill_customer_sk,
        css.total_sales,
        css.total_orders,
        css.avg_order_value,
        ROW_NUMBER() OVER (ORDER BY css.total_sales DESC) AS customer_rank
    FROM SalesSummary css
)

SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    t.total_sales,
    t.total_orders,
    COALESCE(t.avg_order_value, 0) AS avg_order_value
FROM TopCustomers t
LEFT OUTER JOIN customer c ON c.c_customer_sk = t.bill_customer_sk
LEFT JOIN call_center cc ON cc.cc_call_center_sk = (SELECT MIN(cc_call_center_sk) 
                                                     FROM call_center
                                                     WHERE cc_call_center_sk IS NOT NULL)
LEFT JOIN store s ON s.s_store_sk = (SELECT MIN(s_store_sk)
                                      FROM store
                                      WHERE s_store_sk IS NOT NULL)
WHERE t.customer_rank <= 10
  AND c.c_current_addr_sk IS NOT NULL
ORDER BY total_sales DESC
LIMIT 10;
