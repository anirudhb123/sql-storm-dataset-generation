SELECT 
    SUBSTRING(p_name, 1, 10) AS truncated_part_name,
    COUNT(DISTINCT s_suppkey) AS supplier_count,
    AVG(ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT c_name, ', ') AS customer_names,
    MAX(o_orderdate) AS latest_order_date
FROM 
    part
JOIN 
    partsupp ON p_partkey = ps_partkey
JOIN 
    supplier ON ps_suppkey = s_suppkey
JOIN 
    lineitem ON ps_partkey = l_partkey
JOIN 
    orders ON l_orderkey = o_orderkey
JOIN 
    customer ON o_custkey = c_custkey
WHERE 
    p_size > 10
    AND s_acctbal > 5000.00
    AND o_orderstatus = 'F'
GROUP BY 
    SUBSTRING(p_name, 1, 10)
ORDER BY 
    supplier_count DESC, 
    average_supply_cost ASC;
