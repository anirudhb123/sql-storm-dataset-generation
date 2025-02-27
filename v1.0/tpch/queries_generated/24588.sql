WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sale
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
NationPerformance AS (
    SELECT n.n_name, SUM(o.o_totalprice) AS total_orders,
           COUNT(distinct o.o_orderkey) AS order_count,
           CASE WHEN COUNT(distinct o.o_orderkey) > 0 THEN 
               SUM(o.o_totalprice) / COUNT(distinct o.o_orderkey) 
               ELSE NULL 
           END AS avg_order_value
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ns.n_name, rs.s_name, rs.s_acctbal, 
       r.total_sale, hvc.c_name, hvc.c_acctbal,
       np.total_orders, np.avg_order_value
FROM RankedSuppliers rs
JOIN RecentOrders r ON rs.rnk = 1 AND r.o_custkey IN (SELECT c_custkey FROM HighValueCustomers)
JOIN HighValueCustomers hvc ON r.o_custkey = hvc.c_custkey
LEFT JOIN NationPerformance np ON rs.s_suppkey = (SELECT ps.ps_suppkey 
                                                  FROM partsupp ps 
                                                  WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                          FROM part p 
                                                                          WHERE p.p_brand = 'Brand#23'))
WHERE np.avg_order_value IS NOT NULL
ORDER BY np.total_orders DESC, rs.s_acctbal DESC;
