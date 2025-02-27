WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.rn = 1 AND ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = ns.n_nationkey)
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
)
SELECT 
    ts.region_name, 
    ts.nation_name, 
    ts.s_suppkey, 
    ts.s_name, 
    ts.total_supply_cost
FROM 
    TopSuppliers ts
WHERE 
    ts.total_supply_cost > (
        SELECT AVG(total_supply_cost) 
        FROM RankedSuppliers 
        WHERE rn = 1
    )
ORDER BY 
    ts.region_name, ts.nation_name, ts.total_supply_cost DESC;
