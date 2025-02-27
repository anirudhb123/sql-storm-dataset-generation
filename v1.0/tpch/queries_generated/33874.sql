WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
), top_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2022-01-01'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT n.n_name AS nation_name, 
       SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
       COALESCE(AVG(sh.s_acctbal), 0) AS avg_supplier_acctbal,
       COUNT(DISTINCT top.c_custkey) AS high_value_customers
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = s.s_nationkey
LEFT JOIN top_customers top ON top.c_custkey = s.s_suppkey
WHERE n.n_nationkey IS NOT NULL
GROUP BY n.n_name
HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
ORDER BY total_supply_cost DESC
LIMIT 10;
