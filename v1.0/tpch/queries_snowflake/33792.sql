
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 3
),
RevenueByNation AS (
    SELECT n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY n.n_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(total_spent) 
                                    FROM (SELECT SUM(o_totalprice) AS total_spent 
                                          FROM orders 
                                          GROUP BY o_custkey) avg_spending)
)
SELECT 
    r.r_name AS region,
    sh.s_name AS supplier_name,
    rb.total_revenue AS revenue,
    tc.c_name AS customer_name,
    tc.total_spent AS customer_spending,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY rb.total_revenue DESC) AS revenue_rank
FROM region r
LEFT JOIN RevenueByNation rb ON r.r_name = rb.n_name
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = r.r_name LIMIT 1)
LEFT JOIN TopCustomers tc ON rb.total_revenue > tc.total_spent
WHERE rb.total_revenue IS NOT NULL
ORDER BY r.r_name, revenue_rank;
