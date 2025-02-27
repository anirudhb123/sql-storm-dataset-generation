WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.suppkey <> sh.s_suppkey
), 
RecentOrders AS (
    SELECT o_custkey, SUM(o_totalprice) AS total_spent, COUNT(o_orderkey) AS order_count
    FROM orders
    WHERE o_orderdate >= DATE '2023-01-01'
    GROUP BY o_custkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, 
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sales
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerRanking AS (
    SELECT c.c_custkey, c.c_name, ROW_NUMBER() OVER (ORDER BY cr.total_spent DESC) AS rank
    FROM customer c
    JOIN RecentOrders cr ON c.c_custkey = cr.o_custkey
)
SELECT c.c_name, ph.total_available, ph.avg_sales, cr.rank, sh.level
FROM CustomerRanking cr
JOIN PartDetails ph ON cr.rank <= 10
JOIN SupplierHierarchy sh ON sh.s_nationkey = (SELECT n.n_nationkey 
                                                 FROM nation n 
                                                 JOIN customer c ON n.n_nationkey = c.c_nationkey 
                                                 WHERE c.c_custkey = cr.c_custkey)
LEFT JOIN region r ON r.r_regionkey = sh.s_nationkey
WHERE ph.total_available IS NOT NULL
ORDER BY cr.rank, sh.level;
