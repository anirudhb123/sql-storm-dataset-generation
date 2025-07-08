
SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    CONCAT('Total price of part: ', CAST(p.p_retailprice AS CHAR)) AS price_info,
    LEFT(p.p_comment, 20) AS short_comment,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice ELSE 0 END) AS total_filled_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_partkey, p.p_name, r.r_name, n.n_name, p.p_comment, p.p_retailprice
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    total_available_qty DESC, average_supply_cost ASC
LIMIT 100;
