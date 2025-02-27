WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),

OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),

SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),

FilteredCustomer AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (
        SELECT AVG(c_acctbal) * 1.5 FROM customer
    )
)

SELECT d.o_orderkey,
       COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
       f.c_name AS customer_name,
       ds.total_price,
       sh.level AS supplier_level,
       CASE WHEN sh.s_suppkey IS NOT NULL THEN 'High Account Balance Supplier' ELSE 'Regular Supplier' END AS supplier_type
FROM OrderDetails ds
JOIN lineitem l ON ds.o_orderkey = l.l_orderkey
FULL OUTER JOIN SupplierStats s ON l.l_suppkey = s.s_suppkey
INNER JOIN FilteredCustomer f ON f.c_custkey = ds.o_orderkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = l.l_suppkey
WHERE (ds.total_price > 10000 OR f.c_acctbal < 5000)
  AND COALESCE(sh.s_nationkey, f.c_nationkey) IN (SELECT n_nationkey FROM nation WHERE n_name LIKE 'A%')
ORDER BY ds.total_price DESC, supplier_level, customer_name;
