
SELECT 
    p.p_mfgr,
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    ROUND(AVG(p.p_retailprice), 2) AS avg_retail_price,
    LISTAGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_names,
    LISTAGG(DISTINCT c.c_name, ', ') WITHIN GROUP (ORDER BY c.c_name) AS customer_names,
    LISTAGG(DISTINCT n.n_name, ', ') WITHIN GROUP (ORDER BY n.n_name) AS nation_names,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%urgent%'
GROUP BY 
    p.p_mfgr, r.r_name
ORDER BY 
    total_available_quantity DESC, avg_retail_price DESC
LIMIT 50;
