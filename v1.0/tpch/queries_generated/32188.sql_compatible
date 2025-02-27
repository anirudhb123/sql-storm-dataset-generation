
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000  

    UNION ALL

    SELECT p.s_suppkey, p.s_name, p.s_nationkey, h.level + 1
    FROM supplier p
    JOIN SupplierHierarchy h ON p.s_nationkey = h.s_nationkey
    WHERE p.s_acctbal < h.level * 2000  
)
SELECT
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(o.o_totalprice) AS avg_order_price,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    CASE 
        WHEN SUM(l.l_discount) IS NULL THEN 'No Discounts'
        ELSE 'Discounts Available'
    END AS discount_status
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE o.o_orderdate >= DATE '1997-01-01'
AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY n.n_name
HAVING SUM(l.l_extendedprice) > 0
ORDER BY total_revenue DESC
LIMIT 10;
