WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
), 
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        n.n_name LIKE 'A%' 
        AND r.r_name NOT LIKE '%East%'
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    n.n_name AS supplier_nation,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    MAX(p.p_retailprice) AS highest_price,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS comments
FROM 
    RankedParts p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    FilteredNations n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.rn <= 5
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, n.n_name
ORDER BY 
    total_available_quantity DESC;
