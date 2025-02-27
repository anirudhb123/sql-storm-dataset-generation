WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_acctbal > sh.s_acctbal
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierCount AS (
    SELECT ps.ps_partkey, COUNT(ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
)
SELECT c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COALESCE(pc.supplier_count, 0) AS total_suppliers,
       sh.level AS supplier_level
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN PartSupplierCount pc ON l.l_partkey = pc.ps_partkey
JOIN HighValueOrders hvo ON o.o_orderkey = hvo.o_orderkey
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
WHERE l.l_shipdate >= DATE '2023-01-01'
  AND (o.o_totalprice > 500 OR hvo.rn <= 5)
GROUP BY c.c_name, pc.supplier_count, sh.level
ORDER BY total_revenue DESC, c.c_name;
