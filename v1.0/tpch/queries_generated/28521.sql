WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        s.s_name AS supplier_name, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        p.p_brand, 
        p.p_type,
        CONCAT('Part: ', p.p_name, ' | Supplied by: ', s.s_name, ' | Available Quantity: ', ps.ps_availqty) AS part_supplier_info
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
), FilteredDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type,
        pd.part_supplier_info
    FROM part p
    JOIN PartSupplierDetails pd ON p.p_partkey = pd.p_partkey
    WHERE p.p_brand LIKE 'Brand#%27' OR p.p_type LIKE '%tube%' 
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_type,
    COUNT(pd.part_supplier_info) AS supplier_count,
    STRING_AGG(pd.part_supplier_info, '; ') AS all_supplier_info
FROM part p
JOIN FilteredDetails pd ON p.p_partkey = pd.p_partkey
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_type
HAVING COUNT(pd.part_supplier_info) > 1
ORDER BY supplier_count DESC, p.p_name;
