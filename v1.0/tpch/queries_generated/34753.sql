WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level 
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    r.r_name,
    SUM(sp.total_supply_cost) AS total_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    (SELECT AVG(total_revenue) FROM RankedParts WHERE revenue_rank <= 10) AS avg_top_part_revenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
LEFT JOIN customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
GROUP BY r.r_name
HAVING SUM(sp.total_supply_cost) > (SELECT AVG(total_supply_cost) FROM SupplierPerformance)
ORDER BY total_supply_cost DESC;
