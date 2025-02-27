
WITH RECURSIVE SalesCTE AS (
    SELECT
        c.c_customer_id,
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DATE(d.d_date) AS sales_date
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_id, w.w_warehouse_id, DATE(d.d_date)

    UNION ALL

    SELECT
        c.c_customer_id,
        w.w_warehouse_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        DATE(d.d_date) AS sales_date
    FROM
        customer c
    JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN
        warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_id, w.w_warehouse_id, DATE(d.d_date)
),
AddressSales AS (
    SELECT
        ca.ca_city,
        SUM(total_sales) AS total_sales
    FROM
        SalesCTE
    JOIN
        customer_address ca ON ca.ca_address_sk = (
            SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_id = SalesCTE.c_customer_id
        )
    GROUP BY
        ca.ca_city
)
SELECT
    ca.ca_city,
    COALESCE(SUM(as.total_sales), 0) AS city_sales,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    RANK() OVER (ORDER BY COALESCE(SUM(as.total_sales), 0) DESC) AS city_rank
FROM
    customer_address ca
LEFT JOIN
    AddressSales as ON ca.ca_city = as.ca_city
LEFT JOIN
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY
    ca.ca_city
HAVING
    COUNT(DISTINCT c.c_customer_id) > 0
ORDER BY
    city_sales DESC, city_rank;
