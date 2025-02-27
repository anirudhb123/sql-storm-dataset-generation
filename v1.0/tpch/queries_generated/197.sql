WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(s.s_acctbal) AS avg_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
nation_supplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name,
    COALESCE(ns.supplier_count, 0) AS supplier_count,
    SUM(COALESCE(ss.total_cost, 0)) AS total_supplier_cost,
    SUM(os.total_revenue) AS total_order_revenue,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    CASE 
        WHEN SUM(os.total_revenue) > 0 
        THEN SUM(COALESCE(ss.total_cost, 0)) / SUM(os.total_revenue)
        ELSE NULL
    END AS cost_to_revenue_ratio
FROM 
    nation n
LEFT JOIN 
    nation_supplier ns ON n.n_nationkey = ns.n_nationkey
LEFT JOIN 
    supplier_summary ss ON n.n_nationkey = (SELECT s_nationkey FROM supplier s WHERE s.s_suppkey = ss.s_suppkey)
LEFT JOIN 
    order_summary os ON os.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT os.o_orderkey) > 5
ORDER BY 
    total_supplier_cost DESC, n.n_name;
