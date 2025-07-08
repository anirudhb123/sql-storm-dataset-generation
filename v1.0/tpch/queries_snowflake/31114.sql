WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        CAST(s.s_name AS varchar(255)) AS full_name 
    FROM 
        supplier s 
    WHERE 
        s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 

    UNION ALL 

    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        CAST(CONCAT(sh.full_name, ' -> ', s.s_name) AS varchar(255)) 
    FROM 
        supplier s 
    JOIN 
        SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey 
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns_count, 
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS part_rank
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
WHERE 
    l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31' 
    AND o.o_orderstatus IN ('O', 'F')
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000 
    AND COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC, avg_supplier_balance DESC;