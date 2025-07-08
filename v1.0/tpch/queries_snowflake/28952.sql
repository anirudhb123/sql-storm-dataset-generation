
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%steel%'
)
SELECT 
    r.r_name,
    n.n_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    LISTAGG(DISTINCT CONCAT('Part:', p.p_name, ' Brand:', p.p_brand), '; ') WITHIN GROUP (ORDER BY p.p_name) AS part_details
FROM 
    RankedParts p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    p.rnk <= 5
GROUP BY 
    r.r_name, n.n_name, s.s_name, p.p_name, p.p_brand
ORDER BY 
    total_quantity DESC;
