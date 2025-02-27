WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_supplierkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_suppkey IN (SELECT DISTINCT ps_suppkey FROM partsupp WHERE ps_availqty > 100)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
CustomerStats AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
TopCustomers AS (
    SELECT c.c_name, cs.order_count, cs.total_spent,
           DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM CustomerStats cs
    JOIN customer c ON cs.c_custkey = c.c_custkey
    WHERE cs.total_spent IS NOT NULL
)
SELECT 
    sh.s_name AS supplier_name,
    r.r_name AS region_name,
    tc.c_name AS top_customer,
    tc.total_spent,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    MAX(l.l_shipdate) AS last_ship_date
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN supplier sh ON ps.ps_suppkey = sh.s_suppkey
JOIN nation n ON sh.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN TopCustomers tc ON o.o_custkey = tc.c_custkey
WHERE o.o_orderstatus = 'F'
AND (l.l_discount IS NULL OR l.l_discount > 0.05)
GROUP BY sh.s_name, r.r_name, tc.c_name, tc.total_spent
HAVING SUM(l.l_extendedprice) > 10000
ORDER BY total_revenue DESC
LIMIT 10;
