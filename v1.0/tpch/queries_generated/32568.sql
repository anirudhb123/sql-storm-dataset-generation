WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 3000 AND sh.level < 5
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
nation_stats AS (
    SELECT n.n_nationkey, n.n_name, SUM(ps.ps_availqty) AS total_available, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
part_profit AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS profit
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    c.c_name,
    ns.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    MAX(l.l_discount) AS max_discount,
    SUM(pp.profit) AS total_profit,
    sh.level AS supplier_level
FROM customer_summary c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
INNER JOIN nation_stats ns ON c.c_nationkey = ns.n_nationkey
LEFT JOIN part_profit pp ON l.l_partkey = pp.p_partkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = c.c_nationkey
WHERE o.o_orderdate >= '2022-01-01'
  AND (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
GROUP BY c.c_name, ns.n_name, sh.level
HAVING COUNT(DISTINCT o.o_orderkey) > 10
  AND SUM(l.l_extendedprice) IS NOT NULL
ORDER BY total_revenue DESC, total_profit DESC;
