
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 
           0 AS level, CAST(c_customer_sk AS VARCHAR(255)) AS path
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           ch.level + 1,
           CONCAT(ch.path, ' -> ', c.c_customer_sk)
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
), 
SalesMetrics AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_tax) AS total_tax,
        DENSE_RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales cs 
    WHERE cs.cs_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2023
    )
    GROUP BY cs.cs_order_number, cs.cs_item_sk
), 
ShippingModes AS (
    SELECT 
        sm.sm_ship_mode_sk, 
        sm.sm_type,
        ROW_NUMBER() OVER (ORDER BY sm.sm_ship_mode_sk) AS mode_rank
    FROM ship_mode sm
    WHERE sm.sm_carrier IS NOT NULL
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    sm.sm_type,
    sm.mode_rank,
    COALESCE(SUM(sm.total_sales), 0) AS total_sales_amount,
    COALESCE(SUM(sm.total_tax), 0) AS total_tax_amount,
    COUNT(DISTINCT ch.c_customer_sk) AS total_customers,
    CASE 
        WHEN COUNT(DISTINCT ch.c_customer_sk) > 0 THEN AVG(total_sales) 
        ELSE 0 
    END AS avg_sales_per_customer
FROM CustomerHierarchy ch
LEFT JOIN SalesMetrics sm ON ch.c_customer_sk = sm.cs_bill_customer_sk
LEFT JOIN ShippingModes s ON sm.cs_ship_mode_sk = s.sm_ship_mode_sk
GROUP BY ch.c_first_name, ch.c_last_name, sm.sm_type, sm.mode_rank
HAVING SUM(sm.total_sales) > 1000
ORDER BY total_sales_amount DESC, avg_sales_per_customer DESC;
