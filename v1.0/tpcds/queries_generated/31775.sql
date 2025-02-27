
WITH RECURSIVE SalesHierarchy AS (
    SELECT
        cs_sales_price,
        cs_quantity,
        cs_order_number,
        1 AS level
    FROM catalog_sales
    WHERE cs_sold_date_sk = (SELECT MAX(cs_sold_date_sk) FROM catalog_sales)
    
    UNION ALL
    
    SELECT
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_order_number,
        sh.level + 1
    FROM catalog_sales cs
    JOIN SalesHierarchy sh ON cs.cs_order_number = sh.cs_order_number
    WHERE sh.level < 5
),
AggregatedSales AS (
    SELECT
        count(DISTINCT sh.cs_order_number) AS total_orders,
        SUM(sh.cs_sales_price) AS total_sales,
        SUM(sh.cs_quantity) AS total_quantity_sold,
        MAX(sh.cs_sales_price) AS max_sale_price
    FROM SalesHierarchy sh
)
SELECT
    ca.ca_city,
    ca.ca_state,
    COALESCE(A.total_orders, 0) AS total_orders,
    COALESCE(A.total_sales, 0) AS total_sales,
    COALESCE(A.total_quantity_sold, 0) AS total_quantity_sold,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(CASE 
            WHEN cd.cd_marital_status = 'M' THEN 1
            ELSE NULL 
        END) AS marital_rate,
    SUM(CASE
            WHEN hd.hd_income_band_sk IS NULL THEN 1 
            ELSE 0 
        END) AS unbanded_customers
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN AggregatedSales A ON A.total_orders > 0
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_sales DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
