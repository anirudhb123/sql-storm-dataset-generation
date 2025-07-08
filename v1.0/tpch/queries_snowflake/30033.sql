
WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS level,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS rn
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.level + 1,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS rn
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
)

SELECT 
    c.c_name AS customer_name,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    MAX(CASE WHEN l.l_shipdate < '1997-01-01' THEN l.l_shipdate END) AS last_ship_before_1997,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY o.o_totalprice) AS ninety_percentile_order_value,
    LISTAGG(DISTINCT p.p_name, ', ') AS part_names,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_by_revenue
FROM customer c
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
INNER JOIN orders o ON c.c_custkey = o.o_custkey
INNER JOIN lineitem l ON o.o_orderkey = l.l_orderkey
INNER JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
INNER JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE l.l_returnflag = 'N' 
  AND l.l_shipmode IN ('TRUCK', 'AIR')
  AND (p.p_size BETWEEN 10 AND 20 OR ps.ps_supplycost >= 100.00)
GROUP BY c.c_custkey, c.c_name, n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) >= 5
   AND SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY total_revenue DESC
LIMIT 10;
