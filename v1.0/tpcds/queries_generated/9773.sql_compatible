
WITH RankedSales AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_ext_sales_price DESC) AS rn
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    AND d.d_month_seq BETWEEN 1 AND 6
),
TopSales AS (
    SELECT 
        rs.cs_order_number,
        SUM(rs.cs_quantity) AS total_quantity,
        SUM(rs.cs_ext_sales_price) AS total_sales
    FROM RankedSales rs
    WHERE rs.rn <= 5
    GROUP BY rs.cs_order_number
)
SELECT 
    t.cs_order_number,
    t.total_quantity,
    t.total_sales,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    w.w_warehouse_name
FROM TopSales t
JOIN store_sales ss ON ss.ss_order_number = t.cs_order_number
JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN warehouse w ON ss.ss_warehouse_sk = w.w_warehouse_sk
WHERE t.total_sales > 1000
ORDER BY t.total_sales DESC;
