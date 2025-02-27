WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 
           s_comment, 1 AS Level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           s.s_comment, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartPrice AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(CASE WHEN ps.ps_supplycost IS NOT NULL THEN ps.ps_supplycost * ps.ps_availqty ELSE 0 END) AS total_supplycost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (ORDER BY pp.total_supplycost DESC) AS rn
    FROM part p
    JOIN PartPrice pp ON p.p_partkey = pp.p_partkey
    WHERE pp.supplier_count > 0
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           COUNT(l.l_orderkey) AS lineitem_count,
           AVG(l.l_extendedprice) AS avg_extendedprice
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT r.r_name, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       AVG(c.c_acctbal) AS avg_acctbal,
       SUM(CASE WHEN p.p_retailprice > 100 THEN 1 ELSE 0 END) AS high_value_parts,
       SUM(COALESCE(l.l_extendedprice, 0)) AS total_extendedprice
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN (SELECT p.p_partkey, p.p_name FROM TopParts p WHERE p.rn <= 10) p ON 1=1
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
GROUP BY r.r_name
ORDER BY nation_count DESC
LIMIT 5;
