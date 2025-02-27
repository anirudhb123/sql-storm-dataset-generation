WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, 
        p.p_name
),
MaxSuppliers AS (
    SELECT 
        MAX(supplier_count) AS max_suppliers 
    FROM 
        RankedParts
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.supplier_count, 
    rp.total_available, 
    rp.avg_supply_cost, 
    rp.supplier_names
FROM 
    RankedParts rp
JOIN 
    MaxSuppliers ms ON rp.supplier_count = ms.max_suppliers
ORDER BY 
    rp.p_partkey;
