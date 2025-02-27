WITH RECURSIVE nation_cte AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey = (SELECT MIN(n_nationkey) FROM nation)
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nc.level + 1
    FROM nation n
    JOIN nation_cte nc ON n.n_regionkey = nc.n_regionkey
    WHERE nc.level < 5
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
average_prices AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING AVG(ps.ps_supplycost) > 100
),
top_parts AS (
    SELECT p.p_partkey, p.p_name, COALESCE(lp.total_quantity, 0) AS total_quantity
    FROM part p
    LEFT JOIN (
        SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity
        FROM lineitem l
        GROUP BY l.l_partkey
        HAVING SUM(l.l_quantity) > 1000
    ) lp ON p.p_partkey = lp.l_partkey
    ORDER BY total_quantity DESC
    LIMIT 10
)
SELECT 
    n.n_name,
    tp.p_name,
    si.s_name,
    AVG(tp.total_quantity) AS average_total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue
FROM nation_cte n
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN supplier_info si ON l.l_suppkey = si.s_suppkey AND si.rn = 1
JOIN top_parts tp ON l.l_partkey = tp.p_partkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY n.n_name, tp.p_name, si.s_name
HAVING SUM(o.o_totalprice) > 50000
ORDER BY average_total_quantity DESC;
