WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        1 AS order_level
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        oh.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
)
SELECT 
    r.r_name AS region,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS returned_sales,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers,
    AVG(o.o_totalprice) AS average_order_value,
    COUNT(DISTINCT p.p_partkey) AS unique_parts_sold,
    RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
WHERE r.r_name IS NOT NULL
  AND o.o_orderstatus IN ('O', 'F')
  AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY r.r_name
HAVING AVG(o.o_totalprice) > 1000
ORDER BY sales_rank, region;