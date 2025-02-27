SELECT 
    CONCAT('Supplier: ', s_name, ' (', s_suppkey, ')') AS supplier_info,
    GROUP_CONCAT(DISTINCT p_name ORDER BY p_name SEPARATOR ', ') AS products,
    MAX(ps_supplycost) AS max_supply_cost,
    MIN(ps_availqty) AS min_avail_qty,
    AVG(CASE WHEN l_discount > 0 THEN l_discount ELSE NULL END) AS avg_discount_in_lineitems,
    SUM(l_extendedprice) AS total_extended_price,
    COUNT(DISTINCT c_custkey) AS unique_customers
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
WHERE 
    p.p_brand = 'Brand#23' AND 
    s.s_acctbal > 500.00 AND 
    l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    s.suppkey
ORDER BY 
    total_extended_price DESC;
