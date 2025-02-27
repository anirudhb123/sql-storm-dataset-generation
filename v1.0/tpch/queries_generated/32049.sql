WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'FRANCE')

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_line_items,
        DENSE_RANK() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS monthly_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
filtered_orders AS (
    SELECT os.o_orderkey, os.total_revenue, os.o_orderdate
    FROM order_summary os
    WHERE os.total_revenue > (
        SELECT AVG(total_revenue) 
        FROM order_summary
    )
),
region_nation AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COALESCE(MAX(sh.level), 0) AS max_supplier_level,
    rn.region_name,
    rn.nation_name,
    COUNT(DISTINCT fo.o_orderkey) AS order_count
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
JOIN filtered_orders fo ON p.p_partkey = fo.o_orderkey
JOIN region_nation rn ON rn.supplier_count > 0
GROUP BY p.p_name, rn.region_name, rn.nation_name
HAVING SUM(ps.ps_availqty) > 100
ORDER BY total_available_quantity DESC, p.p_name;
