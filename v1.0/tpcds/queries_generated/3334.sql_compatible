
WITH SalesStats AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_price,
        COUNT(ws.ws_item_sk) AS items_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT
        c.c_customer_id,
        ss.total_sales,
        ss.total_orders,
        ss.avg_price,
        ss.items_count,
        CASE
            WHEN ss.total_sales IS NULL THEN 'No Sales'
            WHEN ss.total_sales > 10000 THEN 'Platinum'
            WHEN ss.total_sales BETWEEN 5000 AND 10000 THEN 'Gold'
            WHEN ss.total_sales BETWEEN 1000 AND 5000 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier
    FROM
        SalesStats ss
    JOIN
        customer c ON ss.c_customer_id = c.c_customer_id
    WHERE
        ss.sales_rank <= 10
)
SELECT
    hvc.c_customer_id,
    hvc.total_sales,
    hvc.total_orders,
    hvc.avg_price,
    hvc.items_count,
    hvc.customer_tier,
    COALESCE((
        SELECT
            MAX(cr.cr_return_amount)
        FROM
            catalog_returns cr
        WHERE
            cr.cr_returning_customer_sk = hvc.c_customer_id
    ), 0) AS total_returns,
    CASE 
        WHEN hvc.total_sales > (SELECT AVG(total_sales) FROM HighValueCustomers) 
        THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS sales_comparison
FROM
    HighValueCustomers hvc
ORDER BY
    hvc.total_sales DESC;
