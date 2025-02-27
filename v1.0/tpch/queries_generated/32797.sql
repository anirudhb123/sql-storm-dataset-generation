WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    
    UNION ALL
    
    SELECT r.r_regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON rh.r_regionkey != r.r_regionkey
    WHERE r.r_name LIKE '%North%'
),

CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

SupplierPartAvailability AS (
    SELECT ps.ps_partkey, AVG(ps.ps_availqty) AS avg_avail_qty, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    INNER JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY ps.ps_partkey
),

PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, COALESCE(s.pa, 0) AS avg_avail_qty, COALESCE(s.tsc, 0) AS total_supply_cost
    FROM part p
    LEFT JOIN (
        SELECT ps.ps_partkey, 
               AVG(ps.ps_availqty) AS pa, 
               SUM(ps.ps_supplycost) AS tsc
        FROM partsupp ps
        GROUP BY ps.ps_partkey
    ) s ON p.p_partkey = s.ps_partkey
)

SELECT r.r_name AS region_name, 
       COUNT(DISTINCT co.c_custkey) AS num_customers, 
       SUM(co.total_spent) AS total_revenue,
       SUM(pd.p_retailprice * pd.avg_avail_qty) AS potential_revenue,
       CASE WHEN COUNT(pd.p_partkey) = 0 THEN NULL ELSE SUM(pd.p_retailprice) / COUNT(pd.p_partkey) END AS avg_part_price
FROM RegionHierarchy r
JOIN CustomerOrderSummary co ON r.level = 0
JOIN PartDetails pd ON pd.avg_avail_qty > 0
LEFT JOIN nation n ON n.n_nationkey = co.c_custkey
WHERE r.r_regionkey IS NOT NULL OR n.n_name IS NOT NULL
GROUP BY r.r_name
ORDER BY total_revenue DESC
LIMIT 10;
