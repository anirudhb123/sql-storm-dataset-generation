WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_comment,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        MAX(p.p_retailprice) AS max_retail_price,
        STRING_AGG(s.s_name, ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_comment
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    pd.p_size,
    pd.p_container,
    pd.supplier_count,
    pd.average_supply_cost,
    pd.max_retail_price,
    pd.supplier_names
FROM 
    PartDetails pd
WHERE 
    pd.supplier_count > 5 AND 
    pd.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_type LIKE '%metal%')
ORDER BY 
    pd.average_supply_cost DESC;
