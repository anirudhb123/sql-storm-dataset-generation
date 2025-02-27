WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
           COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CASE 
               WHEN c.c_acctbal BETWEEN 10000 AND 20000 THEN 'Medium'
               WHEN c.c_acctbal > 20000 THEN 'High'
               ELSE 'Low'
           END AS customer_value
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, 
           DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS recent_rank
    FROM orders o
    WHERE o.o_orderstatus <> 'F'
)
SELECT r.r_name AS region, 
       COALESCE(s.rank, -1) AS supplier_rank, 
       c.customer_value,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS order_count
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN HighValueCustomers c ON c.c_custkey = (SELECT o.o_custkey 
                                                  FROM RecentOrders o 
                                                  WHERE o.o_orderkey = l.l_orderkey
                                                  LIMIT 1)
LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
WHERE (s.s_acctbal IS NULL OR s.s_acctbal > 5000)
  AND (l.l_returnflag = 'R' OR l.l_linestatus = 'F')
  AND r.r_name LIKE 'N%' 
GROUP BY r.r_name, s.rank, c.customer_value
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
   OR c.customer_value = 'High'
ORDER BY region, total_revenue DESC;
