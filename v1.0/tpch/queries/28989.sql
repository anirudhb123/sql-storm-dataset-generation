SELECT 
    SUM(P.p_size) AS total_part_size,
    R.r_name AS region_name,
    COUNT(DISTINCT S.s_suppkey) AS num_suppliers,
    STRING_AGG(DISTINCT C.c_name, ', ') AS customer_names,
    COUNT(O.o_orderkey) AS total_orders,
    AVG(O.o_totalprice) AS average_order_value
FROM 
    part P
JOIN 
    partsupp PS ON P.p_partkey = PS.ps_partkey
JOIN 
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN 
    customer C ON S.s_nationkey = C.c_nationkey
JOIN 
    orders O ON C.c_custkey = O.o_custkey
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    P.p_name LIKE '%metal%'
    AND O.o_orderdate >= DATE '1996-01-01'
    AND O.o_orderdate < DATE '1997-01-01'
GROUP BY 
    R.r_name
ORDER BY 
    total_part_size DESC;