WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_acctbal, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.s_acctbal,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    s_acctbal,
    total_supply_cost,
    CONCAT('Supplier: ', supplier_name, ', Total Supply Cost: ', total_supply_cost) AS supplier_info,
    LENGTH(CONCAT('Supplier: ', supplier_name, ', Total Supply Cost: ', total_supply_cost)) AS info_length
FROM 
    TopSuppliers
ORDER BY 
    region_name, nation_name, total_supply_cost DESC;
