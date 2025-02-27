WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_name, 
        p.p_mfgr, 
        p.p_type, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        CONCAT(s.s_name, ' supplies ', p.p_name, ' manufactured by ', p.p_mfgr) AS SupplyDetails,
        CONCAT('Region: ', r.r_name, ' | Comment: ', s.s_comment) AS SupplierRegionComment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT 
        s.suppkey, 
        SUM(ps.ps_availqty * ps.ps_supplycost) AS TotalValue
    FROM 
        SupplierPartDetails s
    GROUP BY 
        s.s_suppkey
    ORDER BY 
        TotalValue DESC
    LIMIT 5
)
SELECT 
    sp.SupplyDetails,
    sp.SupplierRegionComment,
    tp.TotalValue
FROM 
    SupplierPartDetails sp
JOIN 
    TopSuppliers tp ON sp.s_suppkey = tp.suppkey
ORDER BY 
    tp.TotalValue DESC;
