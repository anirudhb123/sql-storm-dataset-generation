WITH RECURSIVE sales_cte AS (
    SELECT s_nationkey, SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l_returnflag = 'N'
    GROUP BY s_nationkey
    UNION ALL
    SELECT n.n_nationkey, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN orders o ON n.n_nationkey = o.o_orderkey
    GROUP BY n.n_nationkey
)
SELECT r.r_name, COALESCE(s.total_sales, 0) AS total_sales
FROM region r
LEFT JOIN (
    SELECT r_regionkey, SUM(total_sales) AS total_sales
    FROM sales_cte
    GROUP BY r_regionkey
) s ON r.r_regionkey = s.r_regionkey
WHERE r.r_name LIKE '%North%'
ORDER BY total_sales DESC;

SELECT DISTINCT c.c_name, c.c_acctbal, 
  CASE 
    WHEN c.c_acctbal IS NULL THEN 'No Balance'
    WHEN c.c_acctbal < 1000 THEN 'Low Balance'
    ELSE 'Sufficient Balance'
  END AS balance_status
FROM customer c
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.o_custkey = c.c_custkey 
      AND o.o_totalprice > (
          SELECT AVG(o_totalprice)
          FROM orders
          WHERE o_orderdate >= CURRENT_DATE - INTERVAL '30 days'
      )
)
ORDER BY c.c_acctbal DESC
LIMIT 10;
