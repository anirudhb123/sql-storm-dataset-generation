WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        0 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F' AND 
        o.o_orderdate = (SELECT MAX(o_orderdate) FROM orders)
  
    UNION ALL
  
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = oh.o_orderkey)
    WHERE 
        o.o_orderstatus = 'F' 
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND 
    l.l_shipdate < '1997-02-01' AND 
    (c.c_acctbal IS NOT NULL AND c.c_acctbal > 500)
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC
LIMIT 10;