WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)  -- Filter suppliers with above average balance

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey + 1  -- Recursive connection model for demonstration
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(day, -30, CURRENT_DATE)  -- Orders in the last 30 days
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
SupplierPerformance AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
),
RankedOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.total_revenue,
        RANK() OVER (PARTITION BY ro.o_custkey ORDER BY ro.total_revenue DESC) AS revenue_rank
    FROM RecentOrders ro
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(sp.total_available) AS total_available_parts,
    AVG(sp.total_supplycost) AS avg_supplycost,
    MAX(ro.total_revenue) AS max_order_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN SupplierPerformance sp ON c.c_custkey = sp.ps_partkey
LEFT JOIN RankedOrders ro ON c.c_custkey = ro.o_custkey
WHERE c.c_acctbal IS NOT NULL  -- Filter out customers with no account balance
  AND r.r_comment LIKE '%important%'  -- Involving string expressions
GROUP BY r.r_name
ORDER BY total_customers DESC, max_order_revenue DESC
LIMIT 10;
