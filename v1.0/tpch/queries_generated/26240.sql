WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        total_revenue > 10000
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    rs.s_name AS top_supplier,
    fo.total_revenue,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
JOIN 
    FilteredOrders fo ON ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = fo.o_orderkey)
JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.rn = 1
ORDER BY 
    fo.total_revenue DESC, p.p_name;
