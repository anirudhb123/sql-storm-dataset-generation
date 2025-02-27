WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey != sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal * 0.5
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING total_revenue > 50000
),
OrderStats AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS line_count, AVG(l.l_extendedprice) AS avg_price
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING COUNT(l.l_orderkey) > 0
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT c.c_name, cs.total_spent, p.p_name, tp.total_revenue, 
       CASE 
           WHEN (cs.total_spent IS NULL OR cs.total_spent = 0) THEN 'No Orders'
           ELSE 'Has Orders'
       END AS order_status,
       ROW_NUMBER() OVER (PARTITION BY cs.total_spent ORDER BY tp.total_revenue DESC) AS revenue_rank
FROM CustomerSummary cs
LEFT JOIN TopParts tp ON cs.total_spent > 100000
JOIN part p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 100)
LEFT JOIN SupplierHierarchy sh ON sh.s_acctbal > cs.total_spent
WHERE cs.total_spent IS NOT NULL
ORDER BY cs.total_spent DESC, tp.total_revenue DESC;
