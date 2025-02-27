WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('F', 'O') -- Filtering for specific order statuses
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM CustomerOrders c
    WHERE c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
FinalReport AS (
    SELECT 
        ns.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts,
        AVG(ps.avg_supplycost) AS avg_supply_cost_per_part,
        SUM(co.order_count) AS total_orders,
        SUM(co.total_spent) AS total_revenue
    FROM nation ns
    LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN PartStats p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN HighValueCustomers co ON s.s_nationkey = co.c_custkey
    GROUP BY ns.n_name
)
SELECT 
    nation_name,
    total_suppliers,
    COALESCE(total_supply_cost, 0) AS total_supply_cost,
    COALESCE(total_parts, 0) AS total_parts,
    COALESCE(avg_supply_cost_per_part, 0) AS avg_supply_cost_per_part,
    COALESCE(total_orders, 0) AS total_orders,
    COALESCE(total_revenue, 0) AS total_revenue
FROM FinalReport
ORDER BY total_revenue DESC
LIMIT 10;
