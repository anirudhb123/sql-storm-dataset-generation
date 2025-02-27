
SELECT 
    p.p_partkey, 
    p.p_name, 
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS manufacturer_brand,
    REPLACE(p.p_comment, 'quality', 'excellence') AS improved_comment,
    r.r_name AS region_name, 
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 50.00 
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_mfgr, 
    p.p_brand, 
    r.r_name, 
    n.n_name, 
    s.s_name
ORDER BY 
    total_quantity DESC 
FETCH FIRST 100 ROWS ONLY;
