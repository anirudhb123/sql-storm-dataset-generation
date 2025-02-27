WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        rs.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 5
    GROUP BY 
        r.r_name, rs.s_name
)
SELECT 
    ts.region_name,
    ts.s_name,
    ts.total_supply_cost,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    TopSuppliers ts
LEFT JOIN 
    supplier s ON ts.s_name = s.s_name
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    ts.region_name, ts.s_name, ts.total_supply_cost
ORDER BY 
    ts.region_name, total_revenue DESC;
