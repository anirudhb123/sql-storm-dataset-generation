WITH RECURSIVE nation_hierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 AS level
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           CASE 
               WHEN SUM(ps.ps_availqty) > 1000 THEN 'High Supplier'
               WHEN SUM(ps.ps_availqty) BETWEEN 500 AND 1000 THEN 'Medium Supplier'
               ELSE 'Low Supplier' 
           END AS supplier_type
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
ranked_orders AS (
    SELECT os.*, CASE 
                    WHEN total_revenue IS NULL THEN 'No Revenue'
                    WHEN total_revenue < 1000 THEN 'Low Revenue'
                    ELSE 'High Revenue' 
                END AS revenue_category
    FROM order_summary os
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty,
    SUM(CASE WHEN l.l_returnflag <> 'R' THEN l.l_quantity ELSE 0 END) AS total_shipped_qty,
    ns.n_name AS supplier_nation,
    ss.supplier_type,
    ro.revenue_category,
    COALESCE(MAX(o.o_totalprice), 0) AS max_order_value,
    STRING_AGG(DISTINCT ro.o_orderkey::TEXT, ', ') AS related_orderkeys
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN supplier_stats ss ON l.l_suppkey = ss.s_suppkey
LEFT JOIN nation_hierarchy nh ON ss.s_suppkey = nh.n_nationkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN ranked_orders ro ON o.o_orderkey = ro.o_orderkey
JOIN nation ns ON ss.s_suppkey = ns.n_nationkey
WHERE (p.p_size > 10 AND ss.total_avail_qty > 100) OR (p.p_size IS NULL AND ns.r_name LIKE 'South%')
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, ns.n_name, ss.supplier_type, ro.revenue_category
HAVING COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY p.p_partkey, total_returned_qty DESC NULLS LAST;
