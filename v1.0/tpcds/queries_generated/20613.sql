
WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_country ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank_within_country
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_preferred_cust_flag = 'Y' AND
        ws.ws_sold_date_sk > (
            SELECT MAX(d.d_date_sk)
            FROM date_dim d 
            WHERE d.d_year = 2022
        )
    GROUP BY
        c.c_customer_id
),
filter_sales AS (
    SELECT
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count
    FROM
        customer_sales cs
    WHERE
        cs.rank_within_country <= 5
),
sales_analysis AS (
    SELECT 
        fs.c_customer_id,
        fs.total_sales,
        fs.order_count,
        (SELECT COUNT(DISTINCT c.c_customer_id) FROM customer c WHERE c.c_birth_month = EXTRACT(MONTH FROM CURRENT_DATE) AND c.c_birth_year = EXTRACT(YEAR FROM CURRENT_DATE) - 30) AS birthday_customers,
        (SUM(fs.total_sales) OVER () / NULLIF(SUM(fs.order_count) OVER (), 0)) AS average_order_value,
        CASE 
            WHEN fs.total_sales IS NULL THEN 'No Sales'
            WHEN fs.total_sales = 0 THEN 'Zero Sales'
            ELSE 'Sales Present'
        END AS sales_status
    FROM
        filter_sales fs
)
SELECT 
    sa.c_customer_id,
    sa.total_sales,
    sa.order_count,
    sa.birthday_customers,
    sa.average_order_value,
    sa.sales_status,
    COALESCE(STRING_AGG(DISTINCT CONVERT(VARCHAR, w.w_warehouse_id)), 'No Warehouses') AS associated_warehouses
FROM 
    sales_analysis sa
LEFT JOIN
    store s ON sa.order_count > 0
LEFT JOIN
    inventory i ON s.s_store_sk = i.inv_warehouse_sk
LEFT JOIN
    warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
GROUP BY 
    sa.c_customer_id,
    sa.total_sales,
    sa.order_count,
    sa.birthday_customers,
    sa.average_order_value,
    sa.sales_status
ORDER BY 
    sa.total_sales DESC, 
    sa.order_count DESC
LIMIT 50;
