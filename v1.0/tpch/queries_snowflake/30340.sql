
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CAST(c.c_name AS VARCHAR(100)) AS full_name,
           0 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CONCAT(ch.full_name, ' > ', c.c_name) AS full_name,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
    WHERE c.c_acctbal > 500 AND ch.level < 3
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
),
SupplierStats AS (
    SELECT s.s_suppkey, AVG(ps.ps_supplycost) AS avg_supply_cost, SUM(ps.ps_availqty) AS total_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
OrderDetails AS (
    SELECT o.o_orderkey, COUNT(l.l_linenumber) AS total_lines, 
           SUM(l.l_tax + l.l_discount) AS total_discount_tax,
           MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT ch.full_name AS customer_path, os.total_sales, os.sales_rank, ss.avg_supply_cost, ss.total_avail_qty, od.total_lines,
       CASE 
           WHEN od.total_discount_tax IS NULL THEN 'No Discounts'
           ELSE CONCAT('Discounts: ', ROUND(od.total_discount_tax, 2))
       END AS discount_info
FROM CustomerHierarchy ch
JOIN OrderSummary os ON ch.c_custkey = os.o_custkey
LEFT JOIN SupplierStats ss ON os.o_custkey = ss.s_suppkey
JOIN OrderDetails od ON os.o_orderkey = od.o_orderkey
WHERE ss.avg_supply_cost IS NOT NULL
ORDER BY os.total_sales DESC;