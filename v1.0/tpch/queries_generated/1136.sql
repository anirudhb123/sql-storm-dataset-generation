WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY AVG(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey, 
        COUNT(*) AS supplier_count
    FROM 
        SupplierStats s
    WHERE 
        s.rank <= 3
    GROUP BY 
        s.s_nationkey
)
SELECT 
    r.r_name AS region,
    COALESCE(ts.supplier_count, 0) AS top_supplier_count,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    STRING_AGG(s.s_name, ', ') AS top_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
LEFT JOIN 
    SupplierStats s ON n.n_nationkey = s.s_nationkey AND s.rank <= 3
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
