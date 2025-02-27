
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs.cs_sales_price IS NOT NULL THEN cs.cs_sales_price ELSE 0 END) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk OR d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY
        c.c_customer_id, d.d_year
),
RankedSales AS (
    SELECT
        c.customer_id,
        cs.d_year,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_web_orders,
        cs.total_catalog_orders,
        RANK() OVER (PARTITION BY cs.d_year ORDER BY cs.total_web_sales + cs.total_catalog_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
    WHERE
        cs.total_web_sales + cs.total_catalog_sales > 0
),
TopCustomers AS (
    SELECT
        r.customer_id,
        r.d_year,
        r.total_web_sales,
        r.total_catalog_sales,
        r.sales_rank
    FROM
        RankedSales r
    WHERE
        r.sales_rank <= 10
)
SELECT
    tc.customer_id,
    tc.d_year,
    tc.total_web_sales,
    tc.total_catalog_sales,
    (COALESCE(tc.total_web_sales, 0) + COALESCE(tc.total_catalog_sales, 0)) AS total_sales,
    CASE
        WHEN tc.total_web_sales > tc.total_catalog_sales THEN 'More from Web'
        WHEN tc.total_web_sales < tc.total_catalog_sales THEN 'More from Catalog'
        ELSE 'Equal Sales'
    END AS sales_comparison
FROM
    TopCustomers tc
ORDER BY
    tc.d_year, tc.total_sales DESC;
