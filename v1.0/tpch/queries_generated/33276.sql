WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS depth
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderTotals AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.total_amount) AS total_spent
    FROM customer c
    LEFT JOIN OrderTotals o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT c.c_custkey, c.c_name, cs.order_count, cs.total_spent
    FROM customer c
    JOIN CustomerStats cs ON c.c_custkey = cs.c_custkey
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
),
PartCount AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    p.p_size,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    COALESCE(hc.order_count, 0) AS high_spender_count,
    pc.supplier_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY pc.supplier_count DESC) AS rn
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN HighSpendingCustomers hc ON hc.c_custkey = s.s_nationkey
JOIN PartCount pc ON p.p_partkey = pc.ps_partkey
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice) 
    FROM part p2 
    WHERE p2.p_size IS NOT NULL
) AND pc.supplier_count > 0
ORDER BY rn, p.p_partkey
LIMIT 100;
