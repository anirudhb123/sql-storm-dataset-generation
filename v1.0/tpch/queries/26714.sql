SELECT 
    SPLIT_PART(p.p_name, ' ', 1) AS part_first_word,
    LENGTH(p.p_name) AS part_name_length,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_address, ')'), '; ') AS suppliers_info,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    MAX(o.o_totalprice) AS max_order_price,
    MIN(o.o_orderdate) AS first_order_date,
    AVG(l.l_extendedprice) AS avg_extended_price
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
WHERE 
    p.p_size >= 10 
    AND p.p_comment LIKE '%special%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    part_first_word, part_name_length
ORDER BY 
    part_name_length DESC, supplier_count DESC;