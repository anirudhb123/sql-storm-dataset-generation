WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 10
),
PartStats AS (
    SELECT p.p_partkey, 
           SUM(ps.ps_availqty) AS total_available, 
           AVG(ps.ps_supplycost) AS avg_supply_cost, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey
),
MaxPart AS (
    SELECT MAX(total_available) AS max_available
    FROM PartStats
),
FilteredParts AS (
    SELECT ps.p_partkey,
           ps.total_available,
           ps.avg_supply_cost,
           ps.supplier_count
    FROM PartStats ps
    JOIN MaxPart mp ON ps.total_available = mp.max_available
    WHERE ps.avg_supply_cost > 200.00
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spending
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
NationSupplier AS (
    SELECT n.n_nationkey,
           COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           MAX(s.s_acctbal) AS highest_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
),
FinalResult AS (
    SELECT rp.p_partkey,
           rp.total_available,
           rp.avg_supply_cost,
           c.order_count,
           c.total_spending,
           ns.total_suppliers,
           ns.highest_balance
    FROM FilteredParts rp
    LEFT JOIN CustomerOrders c ON c.order_count > 10
    LEFT JOIN NationSupplier ns ON ns.total_suppliers > 5
)
SELECT DISTINCT 
    f.p_partkey,
    f.total_available,
    f.avg_supply_cost,
    COALESCE(f.order_count, 0) AS order_count,
    COALESCE(f.total_spending, 0) AS total_spending,
    CASE 
        WHEN f.highest_balance IS NULL THEN 'No Suppliers'
        ELSE 'Has Suppliers'
    END AS supplier_status,
    ROW_NUMBER() OVER (PARTITION BY f.p_partkey ORDER BY f.total_spending DESC) AS spending_rank
FROM FinalResult f
WHERE f.avg_supply_cost < (SELECT AVG(avg_supply_cost) FROM FilteredParts)
ORDER BY f.total_available DESC, f.avg_supply_cost ASC
LIMIT 50;
