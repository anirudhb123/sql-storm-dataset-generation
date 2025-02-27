WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
    UNION ALL
    SELECT ch.c_custkey, ch.c_name, ch.c_acctbal, level + 1
    FROM CustomerHierarchy ch
    JOIN orders o ON ch.c_custkey = o.o_custkey
    WHERE level < 3
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM orders o
    GROUP BY o.o_custkey
),
SupplierPerformance AS (
    SELECT ps.ps_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY ps.ps_suppkey
),
NationStats AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_account_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    n.n_name AS nation, 
    COALESCE(cs.total_spent, 0) AS total_customer_spent,
    cs.order_count,
    sp.total_revenue AS supplier_revenue,
    ns.supplier_count,
    ns.avg_account_balance,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY COALESCE(cs.total_spent, 0) DESC) AS rank
FROM NationStats ns
LEFT JOIN OrderSummary cs ON ns.supplier_count > 0
LEFT JOIN SupplierPerformance sp ON ns.supplier_count > 0
JOIN region r ON ns.n_name LIKE CONCAT('%', r.r_name, '%')
WHERE r.r_comment IS NOT NULL
ORDER BY rank, nation;
