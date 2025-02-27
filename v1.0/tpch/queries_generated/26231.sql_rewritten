SELECT 
    P.p_brand, 
    COUNT(DISTINCT PS.ps_suppkey) AS supplier_count, 
    SUM(PS.ps_availqty) AS total_available_qty, 
    AVG(P.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT N.n_name, ', ') AS nations_supplied,
    STRING_AGG(DISTINCT C.c_name, ', ') AS customers_ordered
FROM 
    part P
JOIN 
    partsupp PS ON P.p_partkey = PS.ps_partkey
JOIN 
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
JOIN 
    customer C ON C.c_nationkey = N.n_nationkey
JOIN 
    orders O ON C.c_custkey = O.o_custkey
JOIN 
    lineitem L ON O.o_orderkey = L.l_orderkey AND L.l_partkey = P.p_partkey
WHERE 
    P.p_type LIKE '%metal%' 
    AND L.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    P.p_brand
ORDER BY 
    supplier_count DESC, total_available_qty DESC;