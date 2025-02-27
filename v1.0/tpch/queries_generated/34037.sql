WITH RECURSIVE top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, ts.total_cost + SUM(ps.ps_supplycost * ps.ps_availqty)
    FROM top_suppliers ts
    JOIN supplier s ON s.s_suppkey <> ts.s_suppkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, ts.total_cost
    HAVING ts.total_cost + SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), 
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
), 
lineitem_stats AS (
    SELECT l.l_orderkey, AVG(l.l_discount) AS avg_discount, SUM(l.l_extendedprice) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY l.l_orderkey
)
SELECT ns.n_name, 
       COUNT(DISTINCT co.c_custkey) AS customer_count, 
       SUM(ls.total_revenue) AS total_revenue, 
       SUM(COALESCE(ts.total_cost, 0)) AS supplier_cost
FROM nation ns
LEFT JOIN customer_orders co ON ns.n_nationkey = co.c_custkey
LEFT JOIN lineitem_stats ls ON co.order_count > 5 AND ls.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
LEFT JOIN top_suppliers ts ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ls.l_orderkey))
WHERE ns.n_name IS NOT NULL
GROUP BY ns.n_name
ORDER BY total_revenue DESC
LIMIT 10;
