SELECT 
    P.p_name AS part_name,
    S.s_name AS supplier_name,
    C.c_name AS customer_name,
    COUNT(O.o_orderkey) AS order_count,
    SUM(L.l_extendedprice) AS total_revenue,
    AVG(L.l_quantity) AS avg_quantity_per_order,
    STRING_AGG(DISTINCT CASE WHEN L.l_returnflag = 'R' THEN 'Returned' ELSE 'Not Returned' END, ', ') AS return_status,
    MAX(L.l_shipdate) AS last_ship_date,
    MIN(O.o_orderdate) AS first_order_date,
    CONCAT('Region: ', R.r_name, ', Nation: ', N.n_name) AS geographical_info
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
    P.p_name LIKE '%widget%' 
    AND O.o_orderstatus = 'O' 
GROUP BY 
    P.p_name, S.s_name, C.c_name, R.r_name, N.n_name 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
