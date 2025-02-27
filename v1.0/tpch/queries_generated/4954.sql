WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS ranking
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.r_name,
        ROW_NUMBER() OVER (PARTITION BY s.r_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        SupplierDetails s
    JOIN 
        region r ON s_r_regionkey = r.r_regionkey
    WHERE 
        s.r_name IS NOT NULL
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(MAX(ls.l_extendedprice), 0) AS max_extended_price,
    COALESCE(SUM(ls.l_discount), 0) AS total_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    (SELECT COUNT(*) 
     FROM orders o2 
     WHERE o2.o_orderstatus = 'F'
       AND o2.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31') AS total_fulfilled_orders
FROM 
    part p
LEFT JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey
LEFT JOIN 
    orders o ON ls.l_orderkey = o.o_orderkey
LEFT JOIN 
    TopSuppliers ts ON o.o_custkey = ts.s_suppkey
WHERE 
    p.p_retailprice BETWEEN (SELECT MIN(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 30) 
                        AND (SELECT MAX(p2.p_retailprice) FROM part p2 WHERE p2.p_size >= 30)
GROUP BY 
    p.p_name, p.p_retailprice
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_discount DESC, max_extended_price DESC;
