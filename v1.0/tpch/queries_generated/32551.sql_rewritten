WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
)

SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_order_value,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_discounted_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS products_sold
FROM 
    nation n
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderdate >= '1997-01-01' 
    AND (l.l_shipdate IS NULL OR l.l_returnflag = 'R')
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(o.o_totalprice) > 10000
ORDER BY 
    total_order_value DESC
LIMIT 10;