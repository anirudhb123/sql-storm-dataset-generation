WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal + sh.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
PartSummary AS (
    SELECT 
        p.p_partkey, 
        COUNT(ps.ps_supplycost) AS supply_count, 
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
HighValueCustomers AS (
    SELECT c_custkey, total_spent
    FROM CustomerOrders
    WHERE total_spent > 5000
)
SELECT 
    p.p_name,
    ps.total_supply_cost,
    ps.avg_avail_qty,
    COALESCE(c.order_count, 0) AS order_count,
    NULLIF(sh.level, 1) AS supplier_level
FROM part p
INNER JOIN PartSummary ps ON p.p_partkey = ps.p_partkey
LEFT JOIN HighValueCustomers c ON c.c_custkey = (
    SELECT o.o_custkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_partkey = p.p_partkey
    ORDER BY o.o_totalprice DESC
    LIMIT 1
)
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = p.p_partkey
    ORDER BY ps.ps_supplycost DESC
    LIMIT 1
)
WHERE 
    ps.total_supply_cost > 1000 AND
    (p.p_size > 10 OR EXISTS (SELECT 1 FROM supplier s WHERE s.s_suppkey = sh.s_suppkey AND s.s_acctbal < 500))
ORDER BY 
    p.p_name, 
    ps.total_supply_cost DESC;
