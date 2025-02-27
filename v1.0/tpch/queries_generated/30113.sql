WITH RECURSIVE RegionHierarchy AS (
    SELECT r.r_regionkey, r.r_name, 0 AS level
    FROM region r
    WHERE r.r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey = rh.r_regionkey + 1
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey, c.c_name
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
LineItemAnalysis AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_shipdate DESC) AS rn
    FROM lineitem l
    WHERE l.l_shipdate < CURRENT_DATE - INTERVAL '90 days'
    GROUP BY l.l_orderkey
)
SELECT 
    r.r_name AS region_name,
    c.c_name AS customer_name,
    SUM(li.revenue) AS total_revenue,
    COALESCE(si.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN SUM(li.revenue) > 10000 THEN 'High Value'
        WHEN SUM(li.revenue) BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM RegionHierarchy r
LEFT JOIN CustomerSummary c ON c.total_spent IS NOT NULL
LEFT JOIN LineItemAnalysis li ON c.c_custkey = li.l_orderkey
LEFT JOIN SupplierInfo si ON si.s_nationkey = c.c_nationkey
GROUP BY r.r_name, c.c_name
HAVING SUM(li.revenue) IS NOT NULL 
   OR COUNT(c.c_custkey) > 5
ORDER BY total_revenue DESC, region_name;
