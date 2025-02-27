WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, c.level + 1
    FROM supplier s
    JOIN SupplierCTE c ON s.s_suppkey = c.s_suppkey
    WHERE c.level < 5
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, AVG(ps.ps_supplycost) AS avg_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
HighCostParts AS (
    SELECT p.*, t.total_cost
    FROM PartSummary t
    JOIN part p ON t.p_partkey = p.p_partkey
    WHERE t.total_cost > (SELECT AVG(total_cost) FROM PartSummary)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    c.c_name,
    cp.p_name,
    hp.total_cost,
    co.total_spent,
    COALESCE(co.order_count, 0) AS order_count,
    CASE
        WHEN co.total_spent IS NULL THEN 'No Orders'
        WHEN co.total_spent > 1000 THEN 'High Roller'
        ELSE 'Casual Shopper'
    END AS customer_type,
    RANK() OVER (PARTITION BY co.total_spent > 500 ORDER BY hp.total_cost DESC) AS cost_rank
FROM HighCostParts hp
JOIN CustomerOrders co ON hp.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 1000
)
JOIN part cp ON hp.p_partkey = cp.p_partkey
LEFT JOIN SupplierCTE sc ON sc.s_suppkey = hp.p_partkey
WHERE sc.level IS NOT NULL
ORDER BY hp.total_cost DESC, co.total_spent DESC;
