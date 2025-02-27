SELECT 
    p.p_name, 
    SRS.s_name AS supplier_name,
    CONCAT_WS(', ', C.c_name, C.c_address) AS customer_info,
    COUNT(DISTINCT O.o_orderkey) AS total_orders,
    SUM(L.l_quantity) AS total_quantity,
    AVG(L.l_extendedprice) AS average_price,
    (SELECT COUNT(*) FROM lineitem L2 WHERE L2.l_partkey = p.p_partkey) AS line_count,
    REPLACE(SUBSTRING_INDEX(P.p_comment, ' ', 5), ' ', '-') AS truncated_comment
FROM 
    part P 
JOIN 
    partsupp PS ON P.p_partkey = PS.ps_partkey 
JOIN 
    supplier SRS ON PS.ps_suppkey = SRS.s_suppkey 
JOIN 
    lineitem L ON P.p_partkey = L.l_partkey 
JOIN 
    orders O ON L.l_orderkey = O.o_orderkey 
JOIN 
    customer C ON O.o_custkey = C.c_custkey 
WHERE 
    LENGTH(P.p_name) > 10 AND 
    (SELECT COUNT(*) FROM nation N WHERE N.n_nationkey = SRS.s_nationkey AND N.n_name LIKE '%land%') > 0
GROUP BY 
    P.p_partkey, SRS.s_name, C.c_name, C.c_address
ORDER BY 
    total_orders DESC, average_price ASC
LIMIT 50;
