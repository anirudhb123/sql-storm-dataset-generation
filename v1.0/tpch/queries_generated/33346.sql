WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, 
           s.s_acctbal, s.s_comment, 1 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey 
                            FROM nation n 
                            WHERE n.n_name = 'UNITED STATES')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, 
           s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    p.p_brand,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000 THEN 'High Revenue'
        ELSE 'Normal Revenue'
    END AS revenue_category
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN region r ON s.s_nationkey = (SELECT n.n_nationkey
                                        FROM nation n
                                        WHERE n.n_name = r.r_name)
WHERE o.o_orderdate >= DATE '2023-01-01'
    AND o.o_orderdate < DATE '2024-01-01'
    AND l.l_returnflag = 'R'
GROUP BY p.p_partkey, p.p_name, p.p_brand
HAVING total_revenue > (SELECT AVG(supply_cost) 
                         FROM partsupp 
                         WHERE ps_partkey = p.p_partkey)
ORDER BY total_revenue DESC
LIMIT 10;
