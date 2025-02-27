SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sales_price,
    CONCAT('Part: ', p.p_name, ' - ', p.p_comment) AS part_description,
    SUBSTRING_INDEX(SUBSTRING_INDEX(n.n_name, ' ', -1), ' ', 1) AS nation_last_word
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_brand LIKE 'Brand#%'
    AND l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_comment, n.n_name
HAVING 
    supplier_count > 1
ORDER BY 
    avg_sales_price DESC;
