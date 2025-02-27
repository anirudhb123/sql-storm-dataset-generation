WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
LineItemAnalysis AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
AggregatedRevenue AS (
    SELECT o.o_orderkey, COALESCE(SUM(l.revenue), 0) AS total_revenue, o.o_orderdate
    FROM orders o
    LEFT JOIN LineItemAnalysis l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name,
    COUNT(DISTINCT sh.s_suppkey) AS total_suppliers,
    AVG(co.total_spent) AS average_spent,
    SUM(p.total_cost) AS total_supply_cost,
    SUM(ar.total_revenue) AS total_revenue_collected
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN CustomerOrders co ON co.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderstatus = 'O')
LEFT JOIN PartSupplierDetails p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey))
LEFT JOIN AggregatedRevenue ar ON ar.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
GROUP BY r.r_name
HAVING AVG(co.total_spent) IS NOT NULL AND SUM(ar.total_revenue) > 1000
ORDER BY r.r_name;
