WITH RECURSIVE customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer_orders co
    JOIN orders o ON co.o_orderkey = o.o_orderkey
    JOIN customer c ON c.c_custkey = co.c_custkey
    WHERE o.o_orderdate < CURRENT_DATE - INTERVAL '1 MONTH'
),
part_supplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
region_summary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
),
lineitem_summary AS (
    SELECT l.l_orderkey,
           COUNT(*) AS total_lines,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
order_summary AS (
    SELECT co.c_custkey,
           co.c_name,
           COUNT(DISTINCT co.o_orderkey) AS order_count,
           SUM(ls.total_revenue) AS total_revenue
    FROM customer_orders co
    LEFT JOIN lineitem_summary ls ON co.o_orderkey = ls.l_orderkey
    GROUP BY co.c_custkey, co.c_name
)
SELECT o.c_name,
       o.order_count,
       COALESCE(r.nation_count, 0) AS nation_count,
       ps.total_avail_qty,
       ps.avg_supply_cost
FROM order_summary o
LEFT JOIN region_summary r ON r.nation_count > 2
LEFT JOIN part_supplier ps ON ps.ps_partkey IN (
    SELECT DISTINCT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = o.c_custkey)
)
WHERE o.total_revenue > 10000
ORDER BY o.order_count DESC, o.c_name;
