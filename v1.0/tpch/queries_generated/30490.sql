WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 50
),
Exports AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT o.o_orderkey, o.o_orderstatus, COUNT(DISTINCT l.l_orderkey) as lineitem_count,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       CASE 
           WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL THEN 'No Revenue'
           ELSE 'Revenue Generated'
       END AS revenue_status,
       th.s_name AS top_supplier,
       top_parts.p_name AS top_part_name
FROM orders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = l.l_suppkey
JOIN Exports e ON e.supplier_count > 5
JOIN TopParts top_parts ON top_parts.rn = 1
LEFT JOIN supplier th ON th.s_suppkey = l.l_suppkey
WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate <= '2023-12-31'
GROUP BY o.o_orderkey, o.o_orderstatus, th.s_name, top_parts.p_name
ORDER BY total_revenue DESC;
