WITH RECURSIVE order_hierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        oh.level + 1
    FROM orders o
    JOIN order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5
),
supplier_total AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_suppkey
),
lineitem_metrics AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS total_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_tax) AS avg_tax
    FROM lineitem l
    GROUP BY l.l_orderkey
),
nation_stats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
final_summary AS (
    SELECT 
        oh.o_orderkey,
        oh.o_orderdate,
        lm.total_items,
        lm.total_revenue,
        ns.supplier_count,
        ns.total_acctbal
    FROM order_hierarchy oh
    LEFT JOIN lineitem_metrics lm ON oh.o_orderkey = lm.l_orderkey
    LEFT JOIN nation_stats ns ON ns.supplier_count > 10
)
SELECT 
    fs.o_orderkey,
    fs.o_orderdate,
    COALESCE(fs.total_items, 0) AS total_items,
    COALESCE(fs.total_revenue, 0.00) AS total_revenue,
    fs.supplier_count,
    fs.total_acctbal,
    CASE 
        WHEN fs.total_revenue > 10000 THEN 'High Revenue'
        WHEN fs.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM final_summary fs
ORDER BY fs.o_orderdate DESC, fs.o_orderkey ASC
LIMIT 100;