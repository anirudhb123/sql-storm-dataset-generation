WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_brand AS brand,
        p.p_type AS type,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(SUBSTRING(s.s_address, 1, 20), '...', SUBSTRING_INDEX(s.s_address, ' ', -1)) AS truncated_address,
        REGEXP_REPLACE(s.s_comment, '[^a-zA-Z ]', '') AS sanitized_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 50 AND 
        p.p_size < 100
),
RankedParts AS (
    SELECT 
        supplier_name,
        part_name,
        brand,
        type,
        available_quantity,
        supply_cost,
        ROW_NUMBER() OVER (PARTITION BY brand ORDER BY supply_cost DESC) AS rank
    FROM 
        SupplierParts
)
SELECT 
    supplier_name,
    part_name,
    brand,
    type,
    available_quantity,
    supply_cost,
    rank,
    CASE 
        WHEN rank <= 3 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_category
FROM 
    RankedParts
WHERE 
    LCASE(part_name) LIKE '%widget%'
    OR LCASE(type) LIKE '%widget%'
ORDER BY 
    supplier_name, rank;
