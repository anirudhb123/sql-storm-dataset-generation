SELECT 
    REPLACE(P.p_name, 'part', '') AS modified_part_name,
    CONCAT(S.s_name, ' [', S.s_nationkey, ']') AS supplier_info,
    LENGTH(S.s_comment) AS supplier_comment_length,
    SUBSTRING_INDEX(S.s_address, ',', 1) AS first_line_address,
    COUNT(DISTINCT O.o_orderkey) AS total_orders
FROM 
    part P
JOIN 
    partsupp PS ON P.p_partkey = PS.ps_partkey
JOIN 
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN 
    lineitem L ON PS.ps_partkey = L.l_partkey
JOIN 
    orders O ON L.l_orderkey = O.o_orderkey
WHERE 
    P.p_type LIKE '%metal%' 
    AND O.o_orderstatus = 'F'
    AND S.s_acctbal > 1000
GROUP BY 
    modified_part_name, supplier_info
HAVING 
    total_orders > 5 
ORDER BY 
    supplier_comment_length DESC, modified_part_name ASC;
