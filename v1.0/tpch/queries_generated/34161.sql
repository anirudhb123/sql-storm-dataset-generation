WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, 
           ps.ps_supplycost, 1 AS level
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey

    UNION ALL

    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, 
           ps.ps_availqty + sc.ps_availqty AS ps_availqty, 
           (ps.ps_supplycost + sc.ps_supplycost) / 2 AS ps_supplycost, 
           level + 1
    FROM SupplyChain sc
    JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE level < 3
)

SELECT 
    r.r_name, 
    n.n_name, 
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice END) AS final_orders_total,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(ps.ps_availqty) AS max_avail_qty,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
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
LEFT JOIN 
    orders o ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    r.r_name, n.n_name
HAVING 
    MAX(l.l_discount) > 0.1 OR 
    EXISTS (SELECT 1 FROM SupplyChain sc WHERE sc.ps_partkey = ps.ps_partkey AND sc.level > 1)
ORDER BY 
    customer_count DESC, 
    final_orders_total DESC;
