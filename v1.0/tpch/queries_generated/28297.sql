WITH RankedParts AS (
    SELECT 
        p_name,
        p_brand,
        p_type,
        p_container,
        p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p_brand, p_type ORDER BY p_retailprice DESC) AS rn
    FROM 
        part
),
TopParts AS (
    SELECT 
        p_name,
        p_brand,
        p_type,
        p_container,
        p_retailprice
    FROM 
        RankedParts
    WHERE 
        rn <= 5
),
SupplierParts AS (
    SELECT 
        s.s_name,
        tp.p_name,
        tp.p_brand,
        tp.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_name ORDER BY tp.p_retailprice DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        TopParts tp ON ps.ps_partkey = tp.p_partkey
)
SELECT 
    s_name,
    STRING_AGG(CONCAT(p_name, ' (', p_brand, ', $', p_retailprice, ')'), '; ') AS parts_info,
    SUM(ps_availqty) AS total_available_qty,
    SUM(ps_supplycost) AS total_supply_cost
FROM 
    SupplierParts
WHERE 
    rn <= 3
GROUP BY 
    s_name
ORDER BY 
    total_supply_cost DESC;
