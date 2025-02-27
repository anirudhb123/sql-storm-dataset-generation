WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON n.n_nationkey = (SELECT s.n_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey)
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 3
)
SELECT 
    t.region_name,
    t.nation_name,
    COUNT(t.s_name) AS top_supplier_count,
    SUM(t.total_cost) AS total_top_supplier_cost
FROM 
    TopSuppliers t
GROUP BY 
    t.region_name, t.nation_name
ORDER BY 
    t.region_name, total_top_supplier_cost DESC;
