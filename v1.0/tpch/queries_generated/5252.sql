WITH top_supply_cost AS (
    SELECT ps_partkey, SUM(ps_supplycost) AS total_supply_cost
    FROM partsupp
    GROUP BY ps_partkey
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
top_nation_suppliers AS (
    SELECT s.n_nationkey, SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
    GROUP BY s.n_nationkey
    ORDER BY total_acctbal DESC
    LIMIT 5
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year' AND o.o_orderstatus = 'O'
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    JOIN filtered_orders fo ON l.l_orderkey = fo.o_orderkey
    GROUP BY l.l_orderkey
)
SELECT n.n_name, COUNT(DISTINCT fo.o_orderkey) AS order_count, SUM(ls.revenue) AS total_revenue
FROM nation n
JOIN top_nation_suppliers tns ON n.n_nationkey = tns.n_nationkey
JOIN lineitem_summary ls ON ls.l_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#23')))
JOIN filtered_orders fo ON ls.l_orderkey = fo.o_orderkey
GROUP BY n.n_name
ORDER BY total_revenue DESC;
