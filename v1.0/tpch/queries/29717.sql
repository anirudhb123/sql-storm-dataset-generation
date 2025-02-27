WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        p.p_brand,
        p.p_type,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
ConcatenatedDetails AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        STRING_AGG(CONCAT(sp.p_name, ' (', sp.p_brand, ')'), ', ') AS part_details
    FROM 
        SupplierParts sp
    JOIN 
        HighValueSuppliers hvs ON sp.s_suppkey = hvs.s_suppkey
    GROUP BY 
        sp.s_suppkey, sp.s_name
)
SELECT 
    s.s_suppkey,
    s.s_name,
    COUNT(*) AS number_of_parts,
    cd.part_details
FROM 
    HighValueSuppliers hvs
JOIN 
    ConcatenatedDetails cd ON hvs.s_suppkey = cd.s_suppkey
JOIN 
    supplier s ON hvs.s_suppkey = s.s_suppkey
GROUP BY 
    s.s_suppkey, s.s_name, cd.part_details
ORDER BY 
    number_of_parts DESC, s.s_name;
