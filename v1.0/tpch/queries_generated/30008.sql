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
        level + 1
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
        s.n_nationkey,
        s.n_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        NationSuppliers ns
    JOIN 
        lineitem l ON ns.s_suppkey = l.l_suppkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.n_nationkey, s.n_name
)
SELECT 
    r.r_name,
    SUM(COALESCE(sos.total_orders, 0)) AS total_orders,
    SUM(sos.total_revenue) AS total_revenue,
    SUM(sos.total_revenue) / NULLIF(SUM(sos.total_orders), 0) AS avg_revenue_per_order
FROM 
    region r
LEFT JOIN 
    SupplierOrderSummary sos ON r.r_regionkey = sos.n_nationkey
GROUP BY 
    r.r_name
HAVING 
    SUM(sos.total_revenue) > 500000
ORDER BY 
    avg_revenue_per_order DESC
LIMIT 10;
