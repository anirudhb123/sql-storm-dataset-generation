
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS average_price,
    STRING_AGG(DISTINCT CONCAT(l.l_returnflag, '-', l.l_linestatus), ', ') AS return_status_summary,
    REPLACE(REPLACE(p.p_comment, 'damaged', 'repaired'), 'defective', 'corrected') AS modified_comment
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
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_acctbal > 10000 AND 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name, l.l_extendedprice, l.l_discount, p.p_comment
HAVING 
    AVG(l.l_discount) > 0.05
ORDER BY 
    total_orders DESC, average_price ASC;
