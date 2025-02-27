WITH RECURSIVE RecursiveSupplier AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS Level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, r.Level + 1
    FROM supplier s
    JOIN RecursiveSupplier r ON s.s_suppkey = r.s_suppkey
    WHERE s.s_acctbal < r.s_acctbal
),
AggregateOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
SupplierLineItem AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
MaxRevenue AS (
    SELECT ps.ps_partkey, MAX(total_revenue) AS max_revenue
    FROM SupplierLineItem ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_name,
    s.s_name,
    a.total_spent,
    r.Level,
    COALESCE(m.max_revenue, 0) AS max_part_revenue
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN AggregateOrders a ON a.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = s.s_nationkey)
LEFT JOIN RecursiveSupplier r ON s.s_suppkey = r.s_suppkey
LEFT JOIN MaxRevenue m ON ps.ps_partkey = m.ps_partkey
WHERE p.p_retailprice > 100
  AND s.s_acctbal IS NOT NULL
  AND (a.total_spent > 5000 OR a.total_spent IS NULL)
ORDER BY total_spent DESC, max_part_revenue ASC;
