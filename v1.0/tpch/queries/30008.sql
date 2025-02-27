
WITH RECURSIVE NationSuppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        1 AS level
    FROM 
        nation n 
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        s.s_acctbal > 100000
    UNION ALL
    SELECT 
        ns.n_nationkey,
        ns.n_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ns.level + 1
    FROM 
        NationSuppliers ns
    JOIN 
        supplier s ON ns.n_nationkey = s.s_nationkey
    WHERE 
        s.s_acctbal > 100000
        AND s.s_suppkey <> ns.s_suppkey
),
SupplierOrderSummary AS (
    SELECT 
        ns.n_nationkey,
        ns.n_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        NationSuppliers ns
    JOIN 
        lineitem l ON ns.s_suppkey = l.l_suppkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        ns.n_nationkey, ns.n_name
)
SELECT 
    r.r_name,
    SUM(COALESCE(sos.total_orders, 0)) AS total_orders,
    SUM(COALESCE(sos.total_revenue, 0)) AS total_revenue,
    NULLIF(SUM(COALESCE(sos.total_orders, 0)), 0) AS total_orders_non_zero,
    SUM(COALESCE(sos.total_revenue, 0)) / NULLIF(SUM(COALESCE(sos.total_orders, 0)), 0) AS avg_revenue_per_order
FROM 
    region r
LEFT JOIN 
    SupplierOrderSummary sos ON r.r_regionkey = sos.n_nationkey
GROUP BY 
    r.r_name
HAVING 
    SUM(COALESCE(sos.total_revenue, 0)) > 500000
ORDER BY 
    avg_revenue_per_order DESC
LIMIT 10;
