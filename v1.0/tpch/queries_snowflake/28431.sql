
SELECT 
    p.p_name, 
    p.p_brand, 
    SUBSTR(p.p_comment, 1, 20) AS short_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(s.s_acctbal) AS average_supplier_balance
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
WHERE 
    p.p_brand LIKE 'Brand#%' AND 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    p.p_name, 
    p.p_brand, 
    SUBSTR(p.p_comment, 1, 20)
ORDER BY 
    total_sales DESC;
