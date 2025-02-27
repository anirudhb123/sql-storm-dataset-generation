WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY COUNT(ps.ps_partkey) DESC, total_supply_cost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    r.r_name AS region_name,
    ts.s_suppkey,
    ts.s_name,
    ts.rank,
    rs.part_count,
    rs.total_supply_cost
FROM 
    TopSuppliers ts
JOIN 
    RankedSuppliers rs ON ts.s_suppkey = rs.s_suppkey
JOIN 
    region r ON ts.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
WHERE 
    ts.rank <= 5 AND rs.total_supply_cost > 100000
ORDER BY 
    r.r_name, ts.rank;
