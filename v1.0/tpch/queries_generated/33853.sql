WITH RECURSIVE SuppOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate <= '2023-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) + so.total_revenue AS total_revenue
    FROM 
        supplier s
    JOIN 
        SuppOrders so ON s.s_suppkey = so.s_suppkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate < '2023-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TotalSuppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(so.total_revenue) AS total_revenue
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SuppOrders so ON s.s_suppkey = so.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    ts.supplier_count,
    COALESCE(ts.total_revenue, 0) AS total_revenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    TotalSuppliers ts ON n.n_nationkey = ts.n_nationkey
ORDER BY 
    region_name, nation_name;
