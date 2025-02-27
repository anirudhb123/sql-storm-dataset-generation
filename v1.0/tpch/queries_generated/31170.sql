WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > 100000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartSupplierCounts AS (
    SELECT ps_partkey, COUNT(ps_suppkey) AS supplier_count
    FROM partsupp
    GROUP BY ps_partkey
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, p.p_size,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    JOIN PartSupplierCounts ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.supplier_count > 5
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
HighSpenderSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s1.s_acctbal) FROM supplier s1
    )
)
SELECT cu.c_name,
       p.p_name AS top_part_name,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COALESCE(SUM(sh.hierarchy_level), 0) AS supplier_level_sum
FROM customerOrderStats cu
JOIN orders o ON cu.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN TopParts p ON l.l_partkey = p.p_partkey
LEFT JOIN SupplierHierarchy sh ON cu.c_custkey = sh.s_nationkey
WHERE o.o_orderdate >= '2023-01-01' 
  AND o.o_orderdate < '2023-12-31'
GROUP BY cu.c_name, p.p_name
HAVING COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) > 10000
ORDER BY total_revenue DESC;
