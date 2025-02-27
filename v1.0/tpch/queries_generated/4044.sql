WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
recent_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATEADD(month, -6, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.total_revenue,
        COALESCE(RANK() OVER (ORDER BY o.total_revenue DESC), 0) AS revenue_rank
    FROM 
        customer c
    LEFT JOIN 
        recent_orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(MAX(r.total_revenue), 0) AS max_revenue,
    MAX(CASE WHEN rs.rank = 1 THEN s.s_name END) AS top_supplier
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    order_summary r ON ps.ps_partkey = r.c_custkey
LEFT JOIN 
    ranked_suppliers rs ON rs.s_suppkey = ps.ps_suppkey
GROUP BY 
    ps.ps_partkey, p.p_name
HAVING 
    COALESCE(MAX(r.total_revenue), 0) > 1000
ORDER BY 
    max_revenue DESC;
