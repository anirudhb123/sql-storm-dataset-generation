WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 10
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('F', 'O') OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey
)
SELECT
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    ps.total_supply_cost,
    COALESCE(co.order_count, 0) AS order_count,
    COALESCE(co.total_spent, 0) AS total_spent,
    sh.level,
    RANK() OVER (PARTITION BY p.p_brand ORDER BY ps.total_supply_cost DESC) AS brand_rank
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN CustomerOrders co ON co.c_custkey = (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_name LIKE 'Customer%'
    LIMIT 1
)
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = (
    SELECT MIN(s.s_suppkey)
    FROM supplier s
    WHERE s.s_acctbal > 5000
)
WHERE p.p_size BETWEEN 10 AND 20
ORDER BY p.p_partkey, ps.total_supply_cost DESC;
