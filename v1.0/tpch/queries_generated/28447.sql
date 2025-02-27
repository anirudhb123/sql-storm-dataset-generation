SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_number,
    CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name) AS description,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT n.n_name ORDER BY n.n_name SEPARATOR ', '), ', ', 3) AS nation_names,
    COUNT(DISTINCT o.o_orderkey) OVER (PARTITION BY p.p_partkey) AS total_orders,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS max_returned_price,
    AVG(l.l_discount) AS average_discount,
    COUNT(DISTINCT l.l_linenumber) AS total_lines
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
    p.p_retailprice > 100.00
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, s.s_suppkey, c.c_custkey, o.o_orderkey
HAVING 
    total_orders > 5
ORDER BY 
    part_name, supplier_name;
