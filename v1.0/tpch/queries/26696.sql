SELECT 
    C.c_name AS Customer_Name,
    S.s_name AS Supplier_Name,
    P.p_name AS Part_Name,
    SUM(L.l_quantity) AS Total_Quantity,
    COUNT(DISTINCT O.o_orderkey) AS Total_Orders,
    AVG(L.l_extendedprice) AS Average_Price,
    STRING_AGG(DISTINCT R.r_name, ', ') AS Regions_Supplied
FROM 
    customer C
JOIN 
    orders O ON C.c_custkey = O.o_custkey
JOIN 
    lineitem L ON O.o_orderkey = L.l_orderkey
JOIN 
    partsupp PS ON L.l_partkey = PS.ps_partkey
JOIN 
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN 
    part P ON PS.ps_partkey = P.p_partkey
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    C.c_acctbal > 1000
AND 
    L.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    C.c_name, S.s_name, P.p_name
HAVING 
    SUM(L.l_quantity) > 50
ORDER BY 
    Total_Quantity DESC, Average_Price ASC;