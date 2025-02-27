
SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(l.l_extendedprice) AS max_extended_price,
    MIN(c.c_acctbal) AS min_customer_balance,
    CONCAT(r.r_name, ': ', r.r_comment) AS region_info
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%widget%' 
    AND o.o_orderstatus = 'O' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, r.r_name, r.r_comment
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    AVG(ps.ps_supplycost) DESC, COUNT(DISTINCT ps.ps_suppkey) ASC;
