WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_name LIKE '%Supplier%'
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.p_name,
        sp.ps_supplycost
    FROM 
        SupplierParts sp
    WHERE 
        sp.rn <= 5
),
SupplierDetails AS (
    SELECT 
        t.s_suppkey,
        t.s_name,
        STRING_AGG(t.p_name, ', ') AS top_parts,
        AVG(t.ps_supplycost) AS avg_supplycost
    FROM 
        TopSuppliers t
    GROUP BY 
        t.s_suppkey, t.s_name
)
SELECT 
    d.s_suppkey,
    d.s_name,
    d.top_parts,
    d.avg_supplycost,
    CASE 
        WHEN d.avg_supplycost < 50 THEN 'Low'
        WHEN d.avg_supplycost BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'High'
    END AS cost_category
FROM 
    SupplierDetails d
ORDER BY 
    d.avg_supplycost DESC;
