
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
), RankedSales AS (
    SELECT 
        c_customer_id,
        total_orders,
        total_sales,
        avg_order_value,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM CustomerSales
), HighValueCustomers AS (
    SELECT
        rsc.c_customer_id,
        rsc.total_orders,
        rsc.total_sales,
        CASE 
            WHEN rsc.total_sales > 1000 THEN 'High Value'
            WHEN rsc.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM RankedSales rsc
    WHERE rsc.sales_rank <= 100
)
SELECT 
    hv.c_customer_id,
    hv.total_orders,
    hv.total_sales,
    hv.customer_value,
    COALESCE((SELECT SUM(sr_return_amt) 
               FROM store_returns sr 
               WHERE sr.sr_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = hv.c_customer_id)), 0) AS total_returns,
    (SELECT COUNT(DISTINCT wp.web_page_id)
     FROM web_page wp 
     WHERE wp.wp_customer_sk IS NOT NULL) AS distinct_web_pages_visited
FROM HighValueCustomers hv
ORDER BY hv.total_sales DESC;
