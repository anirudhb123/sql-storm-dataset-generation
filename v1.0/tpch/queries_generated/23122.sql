WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 1 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'EUROPE')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
)

SELECT 
    C.c_name,
    SUM(CASE WHEN L.l_returnflag = 'R' THEN L.l_extendedprice * (1 - L.l_discount) ELSE 0 END) AS returned_sales,
    COUNT(DISTINCT O.o_orderkey) AS total_orders,
    MAX(L.l_shipdate) AS last_ship_date,
    AVG(P.p_retailprice) AS average_retail_price,
    R.r_name AS region_name,
    NTILE(3) OVER (PARTITION BY R.r_name ORDER BY SUM(L.l_extendedprice) DESC) AS sales_bucket,
    CASE 
        WHEN SUM(L.l_quantity) IS NULL THEN 'No Sales'
        WHEN AVG(L.l_tax) > 0.05 THEN 'High Tax Region'
        ELSE 'Normal Tax'
    END AS tax_category
FROM 
    customer C
LEFT JOIN 
    orders O ON C.c_custkey = O.o_custkey
LEFT JOIN 
    lineitem L ON O.o_orderkey = L.l_orderkey
JOIN 
    partsupp PS ON L.l_partkey = PS.ps_partkey
JOIN 
    part P ON PS.ps_partkey = P.p_partkey
JOIN 
    nation N ON C.c_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    C.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    AND O.o_orderstatus = 'F'
    AND L.l_shipinstruct IS NOT NULL
    AND (L.l_discount BETWEEN 0.05 AND 0.2 OR L.l_tax IS NULL)
GROUP BY 
    C.c_name, R.r_name
HAVING 
    COUNT(DISTINCT O.o_orderkey) > 5
    AND AVG(P.p_retailprice) < (SELECT MAX(p_retailprice) FROM part WHERE p_size < 10)
ORDER BY 
    returned_sales DESC, last_ship_date ASC;
