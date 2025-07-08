WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplierHierarchy sh ON ps.ps_partkey IN (
        SELECT p.p_partkey FROM part p
        WHERE p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) FROM part p2
        )
    )
)
SELECT r.r_name AS region, n.n_name AS nation, COUNT(DISTINCT sh.s_suppkey) AS supplier_count, 
       SUM(c.c_acctbal) AS total_acctbal, 
       AVG(o.o_totalprice) AS avg_order_price
FROM SupplierHierarchy sh
JOIN supplier s ON sh.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN customer c ON s.s_nationkey = c.c_nationkey
JOIN orders o ON c.c_custkey = o.o_custkey
WHERE o.o_orderstatus = 'O'
GROUP BY r.r_name, n.n_name
HAVING AVG(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
ORDER BY region, nation;
