WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_totals AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01'
),
aggregated_lineitems AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
           COUNT(DISTINCT li.l_partkey) AS part_count
    FROM lineitem li
    GROUP BY li.l_orderkey
)
SELECT r.r_name, 
       ns.n_name AS supplier_nation, 
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       AVG(s.total_cost) AS average_supplier_cost,
       SUM(alo.revenue) AS total_revenue
FROM region r
LEFT JOIN nation_hierarchy ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN supplier_totals s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN 
           (SELECT p.p_partkey FROM part p WHERE p.p_size > 10))
LEFT JOIN aggregated_lineitems alo ON alo.l_orderkey IN (SELECT o.o_orderkey FROM ranked_orders o WHERE o.rank_order <= 10)
GROUP BY r.r_name, ns.n_name
ORDER BY total_revenue DESC NULLS LAST;