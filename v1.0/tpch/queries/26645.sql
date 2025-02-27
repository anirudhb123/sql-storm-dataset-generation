WITH RankedParts AS (
    SELECT 
        p_name,
        p_type,
        p_brand,
        ROW_NUMBER() OVER (PARTITION BY p_type ORDER BY p_retailprice DESC) AS price_rank
    FROM 
        part
    WHERE 
        p_name LIKE '%steel%'
),
SupplierDetails AS (
    SELECT 
        s_name,
        s_address,
        s_phone,
        nation.n_name AS nation_name,
        STRING_AGG(CONCAT(p_name, ' (', p_brand, ')'), ', ') AS supplied_parts
    FROM 
        supplier 
    JOIN 
        nation ON supplier.s_nationkey = nation.n_nationkey
    JOIN 
        partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
    JOIN 
        part ON partsupp.ps_partkey = part.p_partkey
    WHERE 
        part.p_brand IN (SELECT DISTINCT p_brand FROM RankedParts WHERE price_rank <= 5)
    GROUP BY 
        s_name, s_address, s_phone, nation.n_name
)
SELECT 
    nation_name,
    COUNT(*) AS supplier_count,
    STRING_AGG(CONCAT(s_name, ' (', s_address, ', ', s_phone, ') supplied: ', supplied_parts), '; ') AS supplier_info
FROM 
    SupplierDetails
GROUP BY 
    nation_name
ORDER BY 
    supplier_count DESC;
