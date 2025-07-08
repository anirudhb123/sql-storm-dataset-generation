
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
),
PartAvailability AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_avail, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey 
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT 
    p.p_name,
    pv.total_avail,
    pv.avg_supply_cost,
    COALESCE(hvc.total_spent, 0) AS high_value_spend,
    ROW_NUMBER() OVER(PARTITION BY p.p_type ORDER BY pv.avg_supply_cost DESC) AS rank
FROM part p
LEFT JOIN PartAvailability pv ON p.p_partkey = pv.ps_partkey
LEFT JOIN HighValueCustomers hvc ON hvc.c_custkey IN (
    SELECT o.o_custkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount > 0.2
)
WHERE p.p_size BETWEEN 1 AND 20
ORDER BY p.p_name, high_value_spend DESC;
