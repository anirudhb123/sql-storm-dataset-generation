
SELECT 
    P.p_name AS "Part Name",
    S.s_name AS "Supplier Name",
    C.c_name AS "Customer Name",
    O.o_orderkey AS "Order Key",
    SUM(L.l_extendedprice * (1 - L.l_discount)) AS "Total Sales",
    COUNT(DISTINCT O.o_orderkey) AS "Order Count",
    MAX(P.p_retailprice) AS "Max Retail Price",
    MIN(S.s_acctbal) AS "Min Supplier Account Balance",
    R.r_name AS "Region Name",
    SUBSTRING(P.p_comment, 1, 10) AS "Short Comment"
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
    L.l_shipdate >= DATE '1997-01-01'
    AND L.l_shipdate < DATE '1997-12-31'
    AND C.c_mktsegment = 'BUILDING'
GROUP BY 
    P.p_name, S.s_name, C.c_name, O.o_orderkey, R.r_name, P.p_retailprice, S.s_acctbal, P.p_comment
ORDER BY 
    "Total Sales" DESC
FETCH FIRST 100 ROWS ONLY;
