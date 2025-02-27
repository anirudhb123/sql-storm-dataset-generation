SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING_INDEX(SUBSTRING_INDEX(p.p_name, ' ', 1), ' ', -1) AS first_word_in_part_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(o.o_orderdate) AS latest_order_date,
    GROUP_CONCAT(DISTINCT CONCAT(s.s_name, ': ', s.s_acctbal) ORDER BY s.s_acctbal DESC SEPARATOR '; ') AS supplier_info
FROM 
    lineitem l
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
GROUP BY 
    n.n_name, r.r_name
HAVING 
    total_revenue > 100000
ORDER BY 
    total_revenue DESC;
