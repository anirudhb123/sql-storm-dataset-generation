
WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS depth
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'EUROPE')
    
    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    n.n_name AS supplier_nation,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE NULL END) AS avg_discounted_price,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice) DESC) AS supply_rank
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey AND o.o_orderstatus = 'F'
WHERE 
    p.p_retailprice > 10.00
    AND n.n_nationkey IN (SELECT n_nationkey FROM nation_hierarchy)
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, n.n_name
HAVING 
    SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    n.n_name, total_supply_cost DESC;
