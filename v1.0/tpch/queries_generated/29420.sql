WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.rank <= 3 -- Select top 3 suppliers by account balance per nation
    GROUP BY 
        r.r_name, s.s_name
)
SELECT 
    r_name,
    STRING_AGG(s_name, ', ') AS top_suppliers,
    SUM(total_supply_value) AS combined_supply_value
FROM 
    TopSuppliers
GROUP BY 
    r_name
ORDER BY 
    combined_supply_value DESC;
