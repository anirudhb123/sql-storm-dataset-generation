WITH supplier_totals AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), order_summary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_order_value, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
), ranked_nations AS (
    SELECT n.n_nationkey, n.n_name, RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS national_rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name, COUNT(DISTINCT r.n_nationkey) AS nation_count,
       COALESCE(AVG(st.total_supply_cost), 0) AS avg_supply_cost,
       COALESCE(SUM(os.total_order_value), 0) AS total_customer_order_value,
       SUM(lis.net_revenue) AS total_lineitem_revenue
FROM region r
LEFT JOIN ranked_nations rn ON r.r_regionkey = rn.n_nationkey
LEFT JOIN supplier_totals st ON rn.n_nationkey = st.s_suppkey
LEFT JOIN order_summary os ON os.c_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey = rn.n_nationkey
)
LEFT JOIN lineitem_summary lis ON lis.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_nationkey = rn.n_nationkey
    )
)
GROUP BY r.r_regionkey, r.r_name
HAVING COUNT(DISTINCT rn.n_nationkey) > 0 AND SUM(lis.net_revenue) > 100000
ORDER BY total_customer_order_value DESC, avg_supply_cost DESC;
