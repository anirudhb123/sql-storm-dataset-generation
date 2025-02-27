WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.order_level + 1
    FROM 
        orders o
    INNER JOIN 
        OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name = 'Customer X')
    WHERE 
        o.o_orderdate > (SELECT MIN(o1.o_orderdate) FROM orders o1 WHERE o1.o_custkey = oh.o_orderkey)
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
WHERE 
    l.l_returnflag = 'N' 
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31' 
    AND (r.r_name IS NULL OR r.r_name != 'Europe')
GROUP BY 
    p.p_name,
    p.p_mfgr
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue_rank, 
    total_revenue DESC;
