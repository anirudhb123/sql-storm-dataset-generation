SELECT 
    SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_revenue,
    P.p_name,
    S.s_name,
    C.c_mktsegment,
    N.n_name AS supplier_nation,
    R.r_name AS region_name
FROM 
    lineitem L
JOIN 
    partsupp PS ON L.l_partkey = PS.ps_partkey
JOIN 
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN 
    part P ON L.l_partkey = P.p_partkey
JOIN 
    customer C ON L.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = C.c_custkey)
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    L.l_shipdate >= DATE '2023-01-01' AND L.l_shipdate < DATE '2023-12-31'
GROUP BY 
    P.p_name, S.s_name, C.c_mktsegment, N.n_name, R.r_name
HAVING 
    SUM(L.l_extendedprice * (1 - L.l_discount)) > 1000000
ORDER BY 
    total_revenue DESC;
