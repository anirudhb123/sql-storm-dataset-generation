WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal <= sh.s_acctbal
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
Nations AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    INNER JOIN region r ON n.n_regionkey = r.r_regionkey
),
OrderAnalysis AS (
    SELECT o.o_orderkey, o.o_custkey, COUNT(l.l_linenumber) AS line_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' 
      AND o.o_orderdate <= DATE '2022-12-31'
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT 
    c.c_name,
    Count(DISTINCT o.o_orderkey) AS orders_count,
    COALESCE(SUM(oa.total_value), 0) AS total_order_value,
    COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_balance,
    CASE 
        WHEN SUM(s.s_acctbal) IS NULL THEN 'No Suppliers'
        ELSE 'Suppliers Present'
    END AS supplier_status,
    nh.region_name
FROM customer c
JOIN OrderAnalysis oa ON c.c_custkey = oa.o_custkey
FULL OUTER JOIN Nations nh ON c.c_nationkey = nh.n_nationkey
LEFT JOIN TopSuppliers s ON c.c_custkey = s.s_suppkey
WHERE c.c_acctbal IS NOT NULL
GROUP BY c.c_name, nh.region_name
HAVING SUM(oa.total_value) > 1000
ORDER BY total_order_value DESC;
