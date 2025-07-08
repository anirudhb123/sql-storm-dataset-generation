WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
), 
OrderSummary AS (
    SELECT c_name, COUNT(o_orderkey) AS order_count, SUM(total_revenue) AS total_spent
    FROM CustomerOrders
    GROUP BY c_name
), 
RankedOrders AS (
    SELECT c_name, order_count, total_spent,
           RANK() OVER (ORDER BY total_spent DESC) AS revenue_rank
    FROM OrderSummary
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    p.p_name AS part_name,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(ash.total_spent) AS avg_spent_per_customer,
    MAX(ro.revenue_rank) AS highest_order_rank
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedOrders ro ON c.c_name = ro.c_name
LEFT JOIN 
    (SELECT c_name, SUM(total_spent) AS total_spent FROM RankedOrders GROUP BY c_name) ash ON ash.c_name = c.c_name
GROUP BY 
    r.r_name, n.n_name, p.p_name
HAVING 
    COUNT(o.o_orderkey) > 0 
ORDER BY 
    total_quantity DESC, total_orders DESC
LIMIT 100;
