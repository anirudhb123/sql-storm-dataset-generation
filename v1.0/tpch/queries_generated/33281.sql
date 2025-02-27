WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, o.o_comment, 
           CAST(NULL AS VARCHAR(100)) AS ParentOrder, 1 AS Level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o2.o_orderkey, o2.o_custkey, o2.o_orderdate, o2.o_totalprice, o2.o_comment, 
           oh.o_orderkey AS ParentOrder, ih.Level + 1
    FROM orders o2
    JOIN OrderHierarchy oh ON o2.o_custkey = oh.o_custkey
    WHERE o2.o_orderdate > oh.o_orderdate AND o2.o_orderstatus = 'O'
)

SELECT 
    r.r_name AS Region,
    n.n_name AS Nation,
    COUNT(DISTINCT c.c_custkey) AS CustomerCount,
    SUM(CASE WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS DiscountedSales,
    AVG(ps.ps_supplycost) AS AvgSupplyCost,
    MAX(l.l_shipdate) AS LastShippingDate,
    STRING_AGG(DISTINCT p.p_name || ' (' || p.p_brand || ')', ', ') AS PopularProducts,
    COUNT(DISTINCT oh.o_orderkey) AS TotalOrders
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN OrderHierarchy oh ON c.c_custkey = oh.o_custkey
WHERE l.l_shipdate >= '2023-01-01'
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10 
   AND AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY r.r_name, n.n_name;
