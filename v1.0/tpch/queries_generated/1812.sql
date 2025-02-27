WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS items_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.total_revenue) AS nation_revenue
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        OrderSummary o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(o.total_revenue) IS NOT NULL
),
FinalReport AS (
    SELECT 
        t.n_name,
        t.nation_revenue,
        s.s_name,
        s.total_cost,
        COALESCE(s.total_cost / NULLIF(t.nation_revenue, 0), 0) AS cost_to_revenue_ratio
    FROM 
        TopNations t
    JOIN 
        RankedSuppliers s ON t.n_nationkey = s.s_nationkey
    WHERE 
        s.rnk = 1
)
SELECT 
    fr.n_name AS nation_name,
    fr.s_name AS top_supplier,
    fr.nation_revenue,
    fr.total_cost,
    fr.cost_to_revenue_ratio
FROM 
    FinalReport fr
ORDER BY 
    fr.cost_to_revenue_ratio DESC, fr.nation_revenue DESC;
