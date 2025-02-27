WITH RankedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           DENSE_RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
CurrentYearOrders AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE YEAR(o.o_orderdate) = YEAR(CURRENT_DATE)
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT p.p_name, 
       r.r_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
       AVG(COALESCE(cs.total_revenue, 0)) AS avg_order_revenue,
       COUNT(DISTINCT cs.o_orderkey) AS order_count,
       CASE 
           WHEN COUNT(DISTINCT cs.o_orderkey) > 5 THEN 'High Activity'
           WHEN COUNT(DISTINCT cs.o_orderkey) BETWEEN 1 AND 5 THEN 'Moderate Activity'
           ELSE 'No Activity'
       END AS activity_level
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank = 1
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN CurrentYearOrders cs ON cs.o_custkey = (SELECT c.c_custkey 
                                                    FROM customer c 
                                                    WHERE c.c_nationkey = n.n_nationkey 
                                                    ORDER BY c.c_acctbal DESC 
                                                    LIMIT 1)
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
WHERE p.p_size IS NOT NULL
GROUP BY p.p_name, r.r_name
HAVING SUM(l.l_extendedprice) > 1000.00 
   OR (SUM(l.l_extendedprice) IS NULL AND COUNT(l.l_orderkey) = 0)
ORDER BY total_price DESC, activity_level DESC;
