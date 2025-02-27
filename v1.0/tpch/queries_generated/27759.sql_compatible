
SELECT 
    S.s_name AS Supplier_Name,
    N.n_name AS Nation,
    COUNT(DISTINCT C.c_custkey) AS Unique_Customers,
    SUM(L.l_extendedprice * (1 - L.l_discount)) AS Total_Sales,
    STRING_AGG(DISTINCT P.p_name, ', ') AS Part_Names,
    LEFT(S.s_comment, 30) || '...' AS Short_Comment
FROM 
    supplier S
JOIN 
    partsupp PS ON S.s_suppkey = PS.ps_suppkey
JOIN 
    part P ON PS.ps_partkey = P.p_partkey
JOIN 
    lineitem L ON P.p_partkey = L.l_partkey
JOIN 
    orders O ON L.l_orderkey = O.o_orderkey
JOIN 
    customer C ON O.o_custkey = C.c_custkey
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
WHERE 
    P.p_brand LIKE 'Brand#%'
    AND L.l_shipdate >= DATE '1997-01-01'
    AND L.l_shipdate < DATE '1998-01-01'
GROUP BY 
    S.s_name, N.n_name, S.s_comment
ORDER BY 
    Total_Sales DESC
LIMIT 10;
