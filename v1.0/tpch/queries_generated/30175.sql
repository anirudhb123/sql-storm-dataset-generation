WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 1000
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, SUM(c.c_acctbal) AS total_acctbal
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING total_acctbal > (SELECT AVG(total_acctbal) FROM (SELECT SUM(c_acctbal) AS total_acctbal FROM customer c GROUP BY c.c_nationkey) AS avg_nation_accounts)
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost * ps.ps_availqty) AS avg_supply_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING supplier_count > 2 AND avg_supply_value IS NOT NULL
)
SELECT r.r_name, 
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       SUM(CASE WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_discounted_sales,
       PERCENT_RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
INNER JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
INNER JOIN TopNations tn ON tn.n_nationkey = n.n_nationkey
INNER JOIN PartSupplierStats ps ON ps.p_partkey = l.l_partkey
WHERE o.o_orderstatus = 'O' AND l.l_returnflag IS NULL
GROUP BY r.r_name
ORDER BY total_orders DESC
LIMIT 10;
