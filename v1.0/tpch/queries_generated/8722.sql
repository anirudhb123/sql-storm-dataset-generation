WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(*) AS supplier_count,
        SUM(rs.total_supply_cost) AS total_supply_cost_sum
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.nation_name
    WHERE 
        rs.rank <= 3
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name AS region_name,
    t.supplier_count,
    t.total_supply_cost_sum
FROM 
    TopSuppliers t
JOIN 
    region r ON r.r_name = t.r_name
ORDER BY 
    t.total_supply_cost_sum DESC;
