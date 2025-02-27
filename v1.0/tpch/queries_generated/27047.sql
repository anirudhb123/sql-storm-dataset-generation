SELECT 
    CONCAT_WS(' ', 
        LEFT(p.p_name, 15), 
        SUBSTRING(p.p_comment FROM 1 FOR 10), 
        REPLACE(s.s_name, 'Supplier', 'Sup')));
    
SELECT 
    n.n_name AS nation, 
    r.r_name AS region, 
    SUM(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE 0 
    END) AS revenue_returned, 
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    lineitem l 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    p.p_name LIKE '%wheel%' 
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    revenue_returned DESC
LIMIT 10;
