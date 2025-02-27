WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
    WHERE 
        o.o_orderdate > cast('1998-10-01' as date) - INTERVAL '1 year'
)
SELECT 
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_revenue,
    SUM(ps.ps_availqty) AS total_available,
    r.r_name AS region_name,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 10 AND 
    n.n_comment NOT LIKE '%sample%' AND 
    s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
GROUP BY 
    p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5 AND 
    AVG(l.l_extendedprice * (1 - l.l_discount)) < 1000
ORDER BY 
    avg_revenue DESC;