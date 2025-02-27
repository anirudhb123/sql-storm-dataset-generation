WITH ranked_orders AS (
    SELECT o.o_orderkey,
           o.o_orderstatus,
           o.o_totalprice,
           o.o_orderdate,
           o.o_orderpriority,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01'
), supplier_parts AS (
    SELECT s.s_suppkey,
           p.p_partkey,
           SUM(ps.ps_availqty) AS total_availqty,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, p.p_partkey
), order_details AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
           COUNT(DISTINCT l.l_partkey) AS distinct_parts_count
    FROM lineitem l
    LEFT JOIN ranked_orders ro ON l.l_orderkey = ro.o_orderkey
    WHERE ro.order_rank <= 10
    GROUP BY l.l_orderkey
)
SELECT n.n_name,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       SUM(od.total_price_after_discount) AS total_revenue,
       STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
       COALESCE(MAX(sp.total_availqty), 0) AS max_avail_qty,
       CASE WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN AVG(od.distinct_parts_count) ELSE NULL END AS avg_parts_per_order
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN supplier_parts sp ON s.s_suppkey = sp.s_suppkey
LEFT JOIN orders o ON s.s_suppkey = o.o_custkey
LEFT JOIN order_details od ON o.o_orderkey = od.l_orderkey
WHERE n.n_name IS NOT NULL
  AND (sp.avg_supplycost IS NULL OR sp.avg_supplycost < (SELECT AVG(ps_avg.avg_supplycost) FROM (SELECT ps.ps_supplycost FROM partsupp ps) AS ps_avg))
GROUP BY n.n_name
HAVING SUM(od.total_price_after_discount) > 10000
ORDER BY total_orders DESC, total_revenue DESC;
