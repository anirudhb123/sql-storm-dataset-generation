SELECT 
    CONCAT(SUBSTRING(p_name, 1, 10), '...') AS short_name,
    COUNT(DISTINCT s_suppkey) AS supplier_count,
    AVG(ps_supplycost) AS average_supply_cost,
    SUM(CASE WHEN l_returnflag = 'R' THEN l_quantity ELSE 0 END) AS total_returned_quantity,
    MAX(o_orderdate) AS most_recent_order_date,
    MIN(o_orderdate) AS earliest_order_date,
    GROUP_CONCAT(DISTINCT r_name ORDER BY r_name SEPARATOR ', ') AS region_names
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey
JOIN 
    supplier ON s_suppkey = ps_suppkey
JOIN 
    lineitem ON l_partkey = p_partkey
JOIN 
    orders ON o_orderkey = l_orderkey
JOIN 
    customer ON c_custkey = o_custkey
JOIN 
    nation ON n_nationkey = s_nationkey
JOIN 
    region ON r_regionkey = n_regionkey
WHERE 
    p_size > 10 AND 
    o_orderdate BETWEEN '2020-01-01' AND '2020-12-31'
GROUP BY 
    short_name
HAVING 
    supplier_count > 5
ORDER BY 
    average_supply_cost DESC;
