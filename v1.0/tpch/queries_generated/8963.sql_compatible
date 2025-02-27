
WITH supplier_info AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
popular_parts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 1000
),
recent_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name AS customer_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '12 MONTH'
)
SELECT si.s_name, si.nation_name, si.region_name, pp.ps_partkey, pp.total_avail_qty, ro.o_orderkey, ro.o_totalprice, ro.customer_name
FROM supplier_info si
JOIN popular_parts pp ON si.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = pp.ps_partkey
    ORDER BY ps.ps_supplycost ASC
    LIMIT 1
)
JOIN lineitem li ON pp.ps_partkey = li.l_partkey
JOIN recent_orders ro ON li.l_orderkey = ro.o_orderkey
WHERE li.l_shipmode IN ('AIR', 'MAIL')
ORDER BY si.region_name, pp.total_avail_qty DESC, ro.o_orderdate DESC;
