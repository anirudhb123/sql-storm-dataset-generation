SELECT 
    P.p_name,
    CONCAT(S.s_name, ' (', C.c_name, ')') AS supplier_customer,
    LEFT(P.p_comment, 20) AS short_comment,
    SUM(PS.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT O.o_orderkey) AS total_orders,
    AVG(PS.ps_supplycost) AS average_supply_cost,
    MAX(L.l_discount) AS max_discount
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
    lineitem L ON O.o_orderkey = L.l_orderkey AND P.p_partkey = L.l_partkey
WHERE 
    P.p_size > 10
    AND L.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    P.p_name, S.s_name, C.c_name, P.p_comment
HAVING 
    SUM(PS.ps_availqty) > 100
ORDER BY 
    total_orders DESC, average_supply_cost ASC;