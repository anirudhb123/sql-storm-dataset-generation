WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey AS region_key, r_name AS region_name, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, h.level + 1
    FROM region r
    INNER JOIN RegionHierarchy h ON r.r_regionkey = h.region_key + 1
),
SupplierStats AS (
    SELECT 
        s.nationkey,
        COUNT(*) AS total_suppliers,
        SUM(s.s_acctbal) AS total_account_balance
    FROM supplier s
    GROUP BY s.nationkey
),
PartStats AS (
    SELECT
        p.p_name,
        p.p_type,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_name, p.p_type
),
OrderStatistics AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY c.custkey ORDER BY SUM(o.o_totalprice) DESC) AS ranking
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FilteredResults AS (
    SELECT
        r.region_name,
        COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers,
        PS.avg_supply_cost,
        OS.total_spent AS customer_spending
    FROM RegionHierarchy r
    LEFT JOIN SupplierStats s ON s.nationkey = r.region_key
    LEFT JOIN PartStats PS ON PS.total_available_qty > 100
    LEFT JOIN OrderStatistics OS ON OS.order_count > 10
    WHERE s.total_suppliers IS NOT NULL OR OS.total_spent IS NOT NULL
    GROUP BY r.region_name, PS.avg_supply_cost, OS.total_spent
)
SELECT 
    fr.region_name,
    COALESCE(fr.distinct_suppliers, 0) AS distinct_suppliers,
    COALESCE(fr.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(fr.customer_spending, 0) AS customer_spending
FROM FilteredResults fr
ORDER BY fr.region_name, fr.customer_spending DESC;
