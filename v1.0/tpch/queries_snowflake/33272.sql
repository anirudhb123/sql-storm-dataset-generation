
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000 
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 0 
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01' 
    GROUP BY c.c_custkey, c.c_nationkey
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
DetailReport AS (
    SELECT 
        sh.s_suppkey,
        sh.s_name,
        os.total_orders,
        os.total_spent,
        ps.supplier_count,
        ps.avg_supply_cost,
        COALESCE(psavg.avg_supply_cost, 0) AS adjusted_supply_cost
    FROM SupplierHierarchy sh
    LEFT JOIN OrderSummary os ON os.c_custkey = sh.s_nationkey 
    LEFT JOIN PartSupplier ps ON ps.p_partkey = (SELECT MAX(p.p_partkey) FROM part p WHERE p.p_mfgr = 'Manufacturer A')
    LEFT JOIN (SELECT AVG(ps_supplycost) AS avg_supply_cost FROM partsupp) psavg ON psavg.avg_supply_cost IS NOT NULL
),
FinalReport AS (
    SELECT *,
        CASE 
            WHEN total_orders IS NULL OR supplier_count = 0 THEN 'Inactive'
            ELSE 'Active'
        END AS supplier_status,
        RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM DetailReport
)
SELECT 
    f.s_suppkey,
    f.s_name,
    f.total_orders,
    f.total_spent,
    f.supplier_count,
    f.avg_supply_cost,
    f.adjusted_supply_cost,
    f.supplier_status,
    f.spending_rank
FROM FinalReport f
WHERE f.total_orders > 5 OR f.total_spent > 1000
ORDER BY f.total_spent DESC;
