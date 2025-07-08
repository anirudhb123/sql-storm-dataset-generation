
SELECT 
    p.p_name, 
    p.p_brand, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(p.p_retailprice) AS average_retail_price,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    LISTAGG(DISTINCT n.n_name, ', ') WITHIN GROUP (ORDER BY n.n_name) AS nations_supplied,
    REGEXP_REPLACE(p.p_comment, '[^A-Za-z]+', '') AS comment_words
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    p.p_name, p.p_brand, p.p_partkey, p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    average_retail_price DESC
LIMIT 10;
