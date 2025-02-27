
WITH supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
popular_parts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    JOIN supplier_info si ON ps.ps_suppkey = si.s_suppkey
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 100
),
recent_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '3 MONTH'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT p.p_name, pp.total_available, ro.total_revenue, si.nation_name
FROM part p
JOIN popular_parts pp ON p.p_partkey = pp.ps_partkey
JOIN recent_orders ro ON ro.total_revenue > 1000
JOIN supplier_info si ON si.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pp.ps_partkey)
ORDER BY ro.total_revenue DESC, pp.total_available DESC;
