
SELECT 
    CONCAT_WS(' ', s.s_name, s.s_address) AS supplier_info,
    P.p_name,
    SUM(PS.ps_availqty) AS total_available_quantity,
    AVG(PS.ps_supplycost) AS avg_supply_cost,
    MAX(P.p_retailprice) AS max_retail_price,
    COUNT(DISTINCT O.o_orderkey) AS total_orders,
    R.r_name AS region_name,
    LEFT(N.n_comment, 50) AS nation_comment_preview
FROM 
    supplier s
JOIN 
    partsupp PS ON s.s_suppkey = PS.ps_suppkey
JOIN 
    part P ON PS.ps_partkey = P.p_partkey
JOIN 
    orders O ON O.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = P.p_partkey LIMIT 1)
JOIN 
    nation N ON s.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    P.p_size BETWEEN 10 AND 20
    AND s.s_acctbal > 1000.00
GROUP BY 
    supplier_info, P.p_name, R.r_name, N.n_comment
HAVING 
    SUM(PS.ps_availqty) > 500
ORDER BY 
    total_orders DESC, avg_supply_cost ASC
LIMIT 100;
