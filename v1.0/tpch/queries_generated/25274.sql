WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) as rank,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation_name,
        rs.region_name
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 3
)
SELECT 
    p.p_partkey,
    p.p_name,
    ts.s_name AS supplier_name,
    ts.region_name,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT ts.nation_name, ', ') AS nations_served
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey AND ts.s_suppkey = l.l_suppkey
GROUP BY 
    p.p_partkey, p.p_name, ts.s_name, ts.region_name
ORDER BY 
    total_revenue DESC;
