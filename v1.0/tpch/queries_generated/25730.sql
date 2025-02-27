WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    ts.region,
    ts.nation,
    STRING_AGG(ts.s_name, ', ') AS top_suppliers,
    SUM(ts.total_supply_cost) AS total_supply_cost
FROM 
    TopSuppliers ts
GROUP BY 
    ts.region, ts.nation
ORDER BY 
    ts.region, ts.nation;
