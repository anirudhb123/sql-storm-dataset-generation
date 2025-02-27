WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.custkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, sh.custkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
)

SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) = 0 THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey AND o.o_orderstatus = 'F'
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 20)
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    total_revenue > (SELECT AVG(l2.l_extendedprice) FROM lineitem l2)
ORDER BY 
    total_revenue DESC
LIMIT 10;
