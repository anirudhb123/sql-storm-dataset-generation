SELECT 
    CONCAT(s.s_name, ' supplies ', p.p_name) AS supplier_part,
    REPLACE(LOWER(p.p_comment), 'special', 'common') AS modified_comment,
    LENGTH(p.p_name) AS name_length,
    SUBSTR(p.p_type, 1, 10) AS type_short,
    CONCAT(REGEXP_REPLACE(COALESCE(n.n_name, 'Unknown'), '\\s+', '_'), '_Region') AS nation_region,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    GROUP_CONCAT(DISTINCT CONCAT(c.c_name, ': ', c.c_acctbal) ORDER BY c.c_acctbal DESC SEPARATOR '; ') AS customer_accounts
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    customer c ON c.c_custkey = (SELECT MIN(c2.c_custkey) FROM customer c2 WHERE c2.c_nationkey = s.s_nationkey)
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
GROUP BY 
    supplier_part, modified_comment, name_length, type_short, nation_region
HAVING 
    total_orders > 5
ORDER BY 
    average_supply_cost DESC, name_length ASC;
