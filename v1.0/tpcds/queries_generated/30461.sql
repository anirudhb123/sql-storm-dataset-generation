
WITH RECURSIVE SalesCTE AS (
    SELECT
        cs_order_number,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_item_sk) AS item_count,
        CASE 
            WHEN SUM(cs_ext_sales_price) > 1000 THEN 'High'
            WHEN SUM(cs_ext_sales_price) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM
        catalog_sales
    GROUP BY
        cs_order_number
),
CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_order_value
    FROM
        customer c
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesStats AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY total_order_value DESC) AS rank,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.total_order_value,
        s.sales_category
    FROM
        CustomerSales c
    JOIN
        SalesCTE s ON c.total_order_value >= 0
)
SELECT
    cs.c_first_name,
    cs.c_last_name,
    cs.total_order_value,
    s.sales_category,
    CASE
        WHEN s.rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Regular Customers'
    END AS customer_status
FROM
    SalesStats s
JOIN
    customer c ON s.c_customer_sk = c.c_customer_sk
WHERE
    cs.total_order_value IS NOT NULL
    AND cs.total_order_value > 0
ORDER BY
    cs.total_order_value DESC
LIMIT 100;
