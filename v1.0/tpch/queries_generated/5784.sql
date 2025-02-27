WITH SupplierCost AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.n_nationkey, 
        rc.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY sc.total_cost DESC) AS rn,
        sc.total_cost
    FROM 
        SupplierCost sc
    JOIN 
        supplier s ON sc.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region rc ON n.n_regionkey = rc.r_regionkey
)
SELECT 
    t.r_name AS region, 
    t.s_name AS supplier_name, 
    t.total_cost
FROM 
    TopSuppliers t
WHERE 
    t.rn <= 5
ORDER BY 
    t.r_name, t.total_cost DESC;
