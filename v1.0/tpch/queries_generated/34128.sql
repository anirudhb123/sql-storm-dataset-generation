WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus, o.o_totalprice,
           1 AS level
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus, o.o_totalprice,
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS returned_revenue,
    AVG(CASE WHEN l.l_returnflag = 'N' AND lo.level > 1 THEN l.l_extendedprice END) AS avg_reorder_value,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
JOIN orders o ON o.o_orderkey = l.l_orderkey
JOIN OrderHierarchy lo ON lo.o_orderkey = o.o_orderkey
JOIN customer c ON c.c_custkey = o.o_custkey
WHERE p.p_retailprice > 100
      AND (n.n_comment LIKE '%important%' OR s.s_comment IS NOT NULL)
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY returned_revenue DESC, unique_customers DESC
LIMIT 10;
