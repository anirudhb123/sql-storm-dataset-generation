WITH RecursivePartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        1 AS depth,
        CAST(p.p_name AS VARCHAR(255)) AS full_description
    FROM 
        part p
    UNION ALL
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        rd.depth + 1,
        CAST(rd.full_description || ' | ' || p.p_name AS VARCHAR(255)) 
    FROM 
        part p
    INNER JOIN 
        RecursivePartDetails rd ON p.p_partkey = rd.p_partkey
    WHERE 
        rd.depth < 5
)
SELECT 
    rp.p_partkey,
    rp.full_description,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    MAX(rp.p_retailprice) AS max_retail_price
FROM 
    RecursivePartDetails rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
GROUP BY 
    rp.p_partkey, rp.full_description
ORDER BY 
    total_available_quantity DESC, 
    max_retail_price DESC
LIMIT 100;
