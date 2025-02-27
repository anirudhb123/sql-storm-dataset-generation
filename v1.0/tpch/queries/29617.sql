WITH supplier_part AS (
    SELECT s.s_suppkey, s.s_name, p.p_name, p.p_brand, p.p_mfgr, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
customer_order AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, o.o_orderkey, o.o_orderstatus, o.o_orderpriority, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_linenumber) AS line_count, MAX(l.l_shipdate) AS latest_ship_date
    FROM lineitem l
    GROUP BY l.l_orderkey
),
nation_region AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sp.s_name AS supplier_name,
    sp.p_name AS part_name,
    co.c_name AS customer_name,
    nr.r_name AS region_name,
    SUM(ls.total_revenue) AS total_revenue,
    AVG(sp.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT co.o_orderpriority, ', ') AS order_priorities,
    STRING_AGG(DISTINCT nr.n_name, ', ') AS nation_names
FROM supplier_part sp
JOIN lineitem_summary ls ON sp.s_suppkey = ls.l_orderkey
JOIN customer_order co ON ls.l_orderkey = co.o_orderkey
JOIN nation_region nr ON co.c_nationkey = nr.n_nationkey
WHERE sp.ps_availqty > 0
GROUP BY sp.s_name, sp.p_name, co.c_name, nr.r_name
HAVING COUNT(DISTINCT co.o_orderkey) > 5
ORDER BY total_revenue DESC;
