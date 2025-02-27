WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey = rh.level + 1
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
PartSupplier AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
SalesSummary AS (
    SELECT
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        AVG(l.l_extendedprice) AS avg_price
    FROM lineitem l
    WHERE l.l_shipdate <= '2023-10-01'
    GROUP BY l.l_partkey
),
CompetitivePricing AS (
    SELECT
        p.p_partkey,
        p.p_name,
        ps.avg_supply_cost,
        ss.total_sales,
        ss.avg_price,
        CASE 
            WHEN ss.avg_price IS NULL THEN 'No Sales'
            WHEN ps.avg_supply_cost < ss.avg_price THEN 'Competitive'
            ELSE 'Not Competitive'
        END AS pricing_strategy
    FROM part p
    JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN SalesSummary ss ON p.p_partkey = ss.l_partkey
)
SELECT 
    rh.r_name AS region_name,
    cs.c_name AS customer_name,
    cp.p_name AS part_name,
    cs.total_spent,
    cp.avg_price,
    cp.pricing_strategy
FROM RegionHierarchy rh
JOIN nation n ON n.n_regionkey = rh.r_regionkey
JOIN supplier s ON s.s_nationkey = n.n_nationkey
JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
JOIN CompetitivePricing cp ON ps.ps_partkey = cp.p_partkey
JOIN CustomerStats cs ON cs.c_custkey = s.s_suppkey
ORDER BY rh.r_name, cs.total_spent DESC, cp.pricing_strategy;
