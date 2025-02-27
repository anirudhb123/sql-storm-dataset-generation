WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany')
    WHERE sh.level < 3
),
PartAveragePrice AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 1000
)
SELECT 
    n.n_name AS nation_name,
    p.p_name AS part_name,
    l.l_shipmode AS shipping_mode,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS ranking
FROM nation n
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE o.o_orderstatus = 'O'
  AND (n.n_name LIKE '%land' OR n.n_name IS NULL)
  AND l.l_shipdate >= '1996-01-01'
GROUP BY n.n_name, p.p_name, l.l_shipmode
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(avg_supplycost) FROM PartAveragePrice)
ORDER BY nation_name, total_revenue DESC
LIMIT 100;