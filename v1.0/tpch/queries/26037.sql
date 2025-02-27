
SELECT 
    CONCAT(SUBSTRING(p.p_name, 1, 3), ' - ', SUBSTRING(p.p_comment, 1, 10)) AS part_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS average_supplier_balance,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    CASE 
        WHEN p.p_size < 20 THEN 'Small'
        WHEN p.p_size BETWEEN 20 AND 50 THEN 'Medium'
        ELSE 'Large' 
    END AS size_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND l.l_returnflag = 'N'
GROUP BY 
    part_info, size_category, p.p_size, s.s_acctbal
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
