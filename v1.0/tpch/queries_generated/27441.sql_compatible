
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_revenue,
    STRING_AGG(DISTINCT p.p_name, ', ') AS products_sold,
    AVG(s.s_acctbal) AS average_supplier_balance,
    MAX(l.l_extendedprice) AS max_line_price
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    c.c_mktsegment LIKE '%household%'
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    n.n_name, r.r_name, s.s_acctbal, l.l_extendedprice
ORDER BY 
    total_revenue DESC, nation_name;
