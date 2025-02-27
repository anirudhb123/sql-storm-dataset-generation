
WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) AS rn
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) AS rn
    FROM orders o
    JOIN OrderHierarchy prev ON o.o_custkey = prev.o_custkey
    WHERE o.o_orderdate > prev.o_orderdate
)
SELECT 
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    AVG(o.o_totalprice) AS avg_order_price,
    r.r_name,
    MAX(l.l_shipdate) AS last_ship_date,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 'Active Customer'
        ELSE 'Inactive Customer'
    END AS customer_status
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE o.o_orderstatus IN ('O', 'F')
AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY c.c_name, r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(l.l_extendedprice * (1 - l.l_discount))
                                                      FROM lineitem l
                                                      JOIN orders o ON l.l_orderkey = o.o_orderkey)
ORDER BY total_revenue DESC
LIMIT 10;
