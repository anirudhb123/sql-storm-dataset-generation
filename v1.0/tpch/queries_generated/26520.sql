WITH RankedParts AS (
    SELECT 
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(l.l_extendedprice) AS avg_extended_price,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_name, p.p_brand, p.p_type
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.total_available_quantity,
    rp.avg_extended_price,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments
FROM 
    RankedParts rp
JOIN 
    supplier s ON rp.p_name LIKE '%' || s.s_name || '%'
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_address LIKE '%' || rp.p_type || '%')
WHERE 
    rp.rn <= 5
GROUP BY 
    rp.p_name, rp.p_brand, rp.total_available_quantity, rp.avg_extended_price, r.r_name, n.n_name, s.s_name
ORDER BY 
    rp.total_available_quantity DESC, rp.avg_extended_price DESC;
