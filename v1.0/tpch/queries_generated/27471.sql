SELECT 
    CONCAT('Supplier: ', s_name, ' (', s_acctbal, ') - Products: ', 
           STRING_AGG(CONCAT(p_name, ' [', ps_availqty, ']'), ', ' ORDER BY p_name) 
           ) AS supplier_products 
FROM 
    supplier s 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
GROUP BY 
    s.suppkey, s.s_name, s.s_acctbal 
HAVING 
    SUM(ps.ps_availqty) > 100 
ORDER BY 
    s_name DESC;
