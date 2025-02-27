WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 0 as level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
), CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) as total_spent, COUNT(o.o_orderkey) as order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) as total_available, avg(ps.ps_supplycost) as avg_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ch.c_name,
    ps.p_name,
    ps.total_available,
    ch.total_spent,
    CASE 
        WHEN ch.total_spent IS NULL THEN 'No Orders'
        WHEN ch.total_spent > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END as customer_type,
    ROW_NUMBER() OVER (PARTITION BY ch.c_name ORDER BY ch.total_spent DESC) as order_rank
FROM CustomerOrderSummary ch
LEFT JOIN PartSupplierInfo ps ON ch.total_spent IS NOT NULL
WHERE (ch.order_count > 0 OR ps.total_available IS NOT NULL)
AND (ch.total_spent > 500 OR ps.total_available > 100)
ORDER BY ch.total_spent DESC, ps.total_available ASC
LIMIT 50;
