WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s_suppkey, 
        s_name,
        s_nationkey,
        1 AS level
    FROM supplier
    WHERE s_nationkey IS NOT NULL
    UNION ALL
    SELECT 
        ps.ps_suppkey, 
        s.s_name, 
        s.s_nationkey,
        sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
order_summary AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS total_parts
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
nation_revenues AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(os.total_revenue) AS revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN order_summary os ON o.o_orderkey = os.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
),
region_revenues AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COALESCE(SUM(nr.revenue), 0) AS total_region_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN nation_revenues nr ON n.n_nationkey = nr.n_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
supplier_totals AS (
    SELECT
        sh.level,
        COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
        SUM(p.ps_supplycost) AS total_supplycost
    FROM supplier_hierarchy sh
    JOIN partsupp p ON sh.s_suppkey = p.ps_suppkey
    GROUP BY sh.level
)
SELECT 
    r.r_name,
    r.total_region_revenue,
    st.supplier_count,
    st.total_supplycost
FROM region_revenues r
JOIN supplier_totals st ON r.total_region_revenue > 10000 OR st.supplier_count IS NULL
WHERE r.total_region_revenue > (SELECT AVG(total_region_revenue) FROM region_revenues)
ORDER BY r.total_region_revenue DESC, st.total_supplycost ASC
LIMIT 10;
