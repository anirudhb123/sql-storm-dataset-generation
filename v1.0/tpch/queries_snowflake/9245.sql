
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON r.r_regionkey = (
            SELECT n.n_regionkey 
            FROM nation n 
            WHERE n.n_nationkey = rs.s_nationkey
            LIMIT 1
        )
    WHERE rs.supplier_rank <= 5
)
SELECT 
    ts.r_name AS region_name,
    COUNT(ts.s_name) AS top_supplier_count,
    AVG(ts.total_supply_cost) AS avg_supply_cost
FROM 
    TopSuppliers ts
GROUP BY 
    ts.r_name
ORDER BY 
    top_supplier_count DESC, avg_supply_cost ASC
LIMIT 10;
