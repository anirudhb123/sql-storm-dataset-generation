WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS top_supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers s ON n.n_nationkey = s.s_suppkey AND s.rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.top_supplier_count,
    AVG(s.s_acctbal) AS avg_acctbal,
    SUM(s.total_supply_cost) AS total_cost_per_region
FROM 
    TopSuppliers r
JOIN 
    RankedSuppliers s ON r.top_supplier_count > 0
GROUP BY 
    r.r_name, r.top_supplier_count
ORDER BY 
    total_cost_per_region DESC;
