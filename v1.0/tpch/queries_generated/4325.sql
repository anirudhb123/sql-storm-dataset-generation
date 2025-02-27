WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ps.ps_supplycost) AS median_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spending
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
FinalStats AS (
    SELECT 
        ph.p_partkey,
        ph.p_name,
        ph.total_available_qty,
        ph.total_supply_cost,
        ph.median_supply_cost,
        tc.c_custkey,
        tc.c_name,
        tc.order_count,
        tc.total_spending
    FROM PartSupplierStats ph
    JOIN TopCustomers tc ON ph.total_supply_cost > 1000
)
SELECT 
    fh.p_partkey,
    fh.p_name,
    fh.total_available_qty,
    fh.total_supply_cost,
    fh.median_supply_cost,
    fh.c_custkey,
    fh.c_name,
    fh.order_count,
    fh.total_spending,
    CASE 
        WHEN fh.total_spending IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    CASE 
        WHEN fh.total_supply_cost > (SELECT AVG(total_supply_cost) FROM PartSupplierStats) THEN 'Above Average Supply Cost'
        ELSE 'Below Average Supply Cost'
    END AS supply_cost_status
FROM FinalStats fh
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = fh.total_spending
WHERE fh.total_available_qty > (SELECT AVG(total_available_qty) FROM PartSupplierStats)
ORDER BY fh.total_spending DESC;
