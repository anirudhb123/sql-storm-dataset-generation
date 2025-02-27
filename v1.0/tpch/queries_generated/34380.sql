WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 10000
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > 5000 AND ch.c_custkey != c.c_custkey
),
SupplierAggregates AS (
    SELECT ps.ps_partkey, SUM(s.s_acctbal) AS total_supplier_balance
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
CustomerSummary AS (
    SELECT 
        ch.c_custkey, 
        ch.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        RANK() OVER (PARTITION BY ch.level ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_level
    FROM CustomerHierarchy ch
    LEFT JOIN orders o ON ch.c_custkey = o.o_custkey
    GROUP BY ch.c_custkey, ch.c_name, ch.level
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sa.total_supplier_balance, 0) AS total_supplier_balance,
    COALESCE(cs.total_spent, 0) AS total_spent,
    CASE 
        WHEN cs.rank_within_level IS NOT NULL THEN 'Ranked'
        ELSE 'Unranked'
    END AS customer_rank_status,
    (p.p_retailprice * COALESCE(cs.total_spent, 0) / NULLIF(NULLIF(AVG(cs.total_spent) OVER(), 0), 0)) AS adjusted_price
FROM part p
LEFT JOIN SupplierAggregates sa ON p.p_partkey = sa.ps_partkey
LEFT JOIN CustomerSummary cs ON cs.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderdate < CURRENT_DATE))
ORDER BY p.p_partkey, cs.total_spent DESC;
