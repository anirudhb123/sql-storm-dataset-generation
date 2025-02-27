WITH SupplierParts AS (
    SELECT 
        s.s_name,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        ps.ps_availqty,
        CONCAT(s.s_name, ': ', p.p_name, ' - ', p.p_brand, ' [', p.p_type, ']') AS part_description
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregatedData AS (
    SELECT 
        p_type,
        COUNT(DISTINCT s_name) AS unique_suppliers,
        SUM(ps_availqty) AS total_availqty,
        AVG(p_retailprice) AS avg_price,
        STRING_AGG(part_description, ', ') AS descriptions
    FROM 
        SupplierParts
    GROUP BY 
        p_type
)
SELECT 
    p_type,
    unique_suppliers,
    total_availqty,
    avg_price,
    descriptions
FROM 
    AggregatedData
WHERE 
    unique_suppliers > 1
ORDER BY 
    avg_price DESC;
