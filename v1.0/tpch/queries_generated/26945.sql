SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    o.o_orderkey, 
    l.l_quantity, 
    l.l_extendedprice, 
    SUBSTRING_INDEX(SUBSTRING_INDEX(l.l_comment, ' ', 3), ' ', -3) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_info,
    LEFT(c.c_address, 20) AS short_address
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    l.l_returnflag = 'N' 
    AND o.o_orderdate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
ORDER BY 
    l.l_extendedprice DESC
LIMIT 100;
