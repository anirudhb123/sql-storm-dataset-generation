
WITH RECURSIVE SalesHierarchy AS (
    SELECT s_store_sk, s_store_name, s_number_employees, s_floor_space, 1 AS level
    FROM store
    WHERE s_closed_date_sk IS NULL
    UNION ALL
    SELECT s.s_store_sk, sh.s_store_name, s.s_number_employees, s.s_floor_space, sh.level + 1
    FROM store s
    JOIN SalesHierarchy sh ON s.s_manager = sh.s_store_name
),
SalesData AS (
    SELECT 
        sd.ss_sold_date_sk, 
        sd.ss_item_sk, 
        SUM(sd.ss_quantity) AS total_quantity, 
        SUM(sd.ss_net_paid_inc_tax) AS total_net_paid
    FROM store_sales sd
    WHERE sd.ss_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq = 6
    )
    GROUP BY sd.ss_sold_date_sk, sd.ss_item_sk
),
AggregateSalesData AS (
    SELECT 
        h.s_store_name,
        h.level,
        SUM(sd.total_quantity) AS aggregated_quantity,
        AVG(sd.total_net_paid) AS average_net_paid
    FROM SalesHierarchy h
    JOIN SalesData sd ON h.s_store_sk = sd.ss_store_sk
    GROUP BY h.s_store_name, h.level
)
SELECT 
    a.s_store_name,
    a.level,
    a.aggregated_quantity,
    COALESCE(a.average_net_paid, 0) AS average_net_paid,
    CASE 
        WHEN a.aggregated_quantity > 1000 THEN 'High'
        WHEN a.aggregated_quantity BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low' 
    END AS performance_category
FROM AggregateSalesData a
LEFT JOIN customer c ON c.c_current_addr_sk = a.level
WHERE c.c_preferred_cust_flag = 'Y' OR c.c_birth_country = 'USA'
ORDER BY a.level, a.aggregated_quantity DESC
LIMIT 100;
