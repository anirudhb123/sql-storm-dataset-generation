SELECT 
    P.p_name AS product_name, 
    S.s_name AS supplier_name, 
    C.c_name AS customer_name, 
    O.o_orderkey AS order_key, 
    SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_revenue,
    COUNT(DISTINCT O.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT R.r_name, ', ') AS regions_served
FROM 
    part P
JOIN 
    partsupp PS ON P.p_partkey = PS.ps_partkey
JOIN 
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN 
    lineitem L ON P.p_partkey = L.l_partkey
JOIN 
    orders O ON L.l_orderkey = O.o_orderkey
JOIN 
    customer C ON O.o_custkey = C.c_custkey
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    O.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    AND L.l_returnflag = 'N'
GROUP BY 
    P.p_name, S.s_name, C.c_name, O.o_orderkey
ORDER BY 
    total_revenue DESC, order_count DESC;
