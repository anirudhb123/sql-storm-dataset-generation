WITH RECURSIVE order_hierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, o_orderstatus, 1 AS level
    FROM orders
    WHERE o_orderstatus IN ('A', 'F') AND o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
    
    UNION ALL

    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, oh.level + 1
    FROM orders o
    JOIN order_hierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > (SELECT MAX(o_orderdate) FROM orders WHERE o_orderstatus = 'O')
)

SELECT
    r.r_name AS region_name,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_extendedprice ELSE 0 END) AS total_returns,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY AVG(ps.ps_supplycost) DESC) AS rn
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem li ON li.l_partkey = p.p_partkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    order_hierarchy oh ON oh.o_custkey = c.c_custkey
WHERE 
    (r.r_name IS NOT NULL OR s.s_comment LIKE '%excellent%') 
    AND (p.p_size BETWEEN 1 AND 10 OR p.p_brand = 'Brand#32')
    AND ps.ps_availqty > (SELECT AVG(ps2.ps_availqty) FROM partsupp ps2 WHERE ps2.ps_supplycost < ps.ps_supplycost)
GROUP BY 
    r.r_name
HAVING 
    COUNT(oh.o_orderkey) > 2 
    AND AVG(li.l_discount) IS NULL
    OR total_returns > 500
ORDER BY
    region_name ASC, average_supply_cost DESC
FETCH FIRST 10 ROWS ONLY;
