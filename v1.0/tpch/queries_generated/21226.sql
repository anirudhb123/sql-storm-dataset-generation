WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) -- Start with suppliers above average account balance
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal -- Recursive criteria to find suppliers with lower balance in the same nation
),
CustomerOrders AS (
    SELECT c.c_custkey, c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue, 
           DENSE_RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_shipdate DESC) AS revenue_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
),
FilteredLineItems AS (
    SELECT lis.l_orderkey, lis.net_revenue
    FROM LineItemStats lis
    WHERE lis.revenue_rank = 1 -- Get only the latest revenue per order
),
MostActiveCustomers AS (
    SELECT co.c_custkey, co.total_spent
    FROM CustomerOrders co
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    SUM(CASE 
        WHEN COALESCE(mac.total_spent, 0) > 10000 THEN 1 
        ELSE 0 END) AS high_value_customers
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN FilteredLineItems fli ON fli.l_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    JOIN MostActiveCustomers mac ON mac.c_custkey = o.o_custkey
)
LEFT JOIN MostActiveCustomers mac ON mac.c_custkey = sh.s_nationkey -- Bizarre linkage for illustration
GROUP BY r.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 0
ORDER BY region_name DESC;
