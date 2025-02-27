WITH RECURSIVE part_supply AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER(PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM partsupp ps
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS order_count, 
           o.o_orderdate, 
           CASE WHEN o.o_orderstatus = 'F' THEN 'Finalized' ELSE 'Pending' END AS order_status
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
    HAVING total_revenue > 10000
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name,
           SUM(ps.ps_availqty) AS total_avail_qty,
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN part_supply ps ON s.s_suppkey = ps.ps_suppkey AND ps.rn = 1
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
ranked_orders AS (
    SELECT os.*, RANK() OVER(PARTITION BY os.order_status ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM order_summary os
)
SELECT 
    pi.p_partkey,
    pi.p_name,
    si.s_name,
    si.nation_name,
    ro.total_revenue,
    ro.order_count,
    ro.order_date,
    ro.order_status,
    CASE 
        WHEN si.total_avail_qty IS NULL THEN 'No available stock'
        ELSE CAST(si.total_avail_qty AS varchar) || ' available'
    END AS availability,
    COALESCE(si.unique_parts, 0) AS unique_parts_supplied,
    ROW_NUMBER() OVER(ORDER BY pi.p_partkey) AS part_rank
FROM part AS pi
LEFT JOIN supplier_info AS si ON pi.p_partkey = si.ps_partkey
LEFT JOIN ranked_orders AS ro ON si.s_suppkey = ro.o_orderkey
WHERE pi.p_size > (SELECT AVG(p_size) FROM part WHERE p_container IS NOT NULL)
ORDER BY ro.total_revenue DESC NULLS LAST, si.s_name ASC;
