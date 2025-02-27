WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) FROM supplier s2
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartSupplierStats AS (
    SELECT p.p_partkey, COUNT(ps.ps_suppkey) AS supplier_count, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FinalMetrics AS (
    SELECT 
        ph.p_partkey,
        ph.supplier_count,
        ph.total_supply_cost,
        co.total_spent,
        co.order_count,
        ROW_NUMBER() OVER (PARTITION BY ph.p_partkey ORDER BY co.total_spent DESC) AS spend_rank
    FROM PartSupplierStats ph
    LEFT JOIN CustomerOrderStats co ON ph.p_partkey IN (
        SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (
            SELECT o.o_orderkey FROM orders o WHERE o.o_totalprice BETWEEN 100 AND 500
        )
    )
)
SELECT 
    ph.p_partkey,
    COALESCE(MAX(CASE WHEN sh.level = 0 THEN sh.s_name END), 'N/A') AS highest_level_supplier,
    ph.supplier_count,
    ph.total_supply_cost,
    COALESCE(SUM(co.total_spent), 0) AS total_cust_spending,
    COALESCE(SUM(co.order_count), 0) AS total_orders,
    AVG(ph.total_supply_cost) OVER () AS avg_supply_cost,
    CASE 
        WHEN COALESCE(SUM(co.total_spent), 0) > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value
FROM FinalMetrics ph
LEFT JOIN SupplierHierarchy sh ON ph.p_partkey = sh.s_suppkey
LEFT JOIN CustomerOrderStats co ON ph.p_partkey IN (
    SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (
        SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IS NOT NULL
    )
)
GROUP BY ph.p_partkey, ph.supplier_count, ph.total_supply_cost
ORDER BY ph.p_partkey;
