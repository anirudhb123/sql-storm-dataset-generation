SELECT 
    COUNT(DISTINCT p.p_name) AS unique_parts,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice ELSE 0 END) AS total_freight_sales,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    REGEXP_REPLACE(n.n_name, '.*(US|CAN).*', 'North America') AS region_grouping,
    CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info,
    STRING_AGG(DISTINCT p.p_type, ', ') AS part_types,
    LEFT(c.c_name, 5) AS customer_prefix
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
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'Europe%'
    AND l.l_shipdate > '1997-01-01'
GROUP BY 
    short_comment, region_grouping, supplier_info, customer_prefix
ORDER BY 
    avg_supplier_balance DESC;