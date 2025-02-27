WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 as order_level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, co.order_level + 1
    FROM CustomerOrders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    WHERE o.o_orderdate > (SELECT MAX(o2.o_orderdate) FROM orders o2 WHERE o2.o_custkey = co.c_custkey)
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    COUNT(DISTINCT co.o_orderkey) AS number_of_customer_orders
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey = o.o_orderkey
WHERE 
    r.r_name LIKE 'Europe%' 
    AND p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 50)
    AND s.s_acctbal IS NOT NULL
GROUP BY 
    r.r_name,
    n.n_name,
    s.s_name,
    p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    region_name, 
    nation_name, 
    supplier_name;
