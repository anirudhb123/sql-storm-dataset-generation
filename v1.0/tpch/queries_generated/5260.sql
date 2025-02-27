WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER(PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
        r.r_name AS region,
        ns.n_name AS nation,
        rs.s_name AS supplier_name,
        rs.total_supply_cost
    FROM 
        rankedsuppliers rs
    JOIN 
        nation ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = rs.s_suppkey AND rank = 1)
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    region,
    nation,
    supplier_name,
    total_supply_cost
FROM 
    TopSuppliers
ORDER BY 
    region, total_supply_cost DESC;
