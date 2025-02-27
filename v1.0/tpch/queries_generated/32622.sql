WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_acctbal > sh.s_acctbal * 0.75
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
CustomerRanking AS (
    SELECT c.c_custkey, c.c_name, os.total_revenue,
           RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
)
SELECT 
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(c.c_acctbal) AS avg_account_balance,
    COUNT(sh.s_suppkey) AS active_suppliers
FROM customer c
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey 
                                            FROM part p 
                                            WHERE p.p_brand = 
                                            (SELECT p_brand FROM part WHERE p_size = 15 LIMIT 1))
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = c.c_nationkey
WHERE c.c_mktsegment = 'BUILDING' AND c.c_acctbal IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(c.c_custkey) > 5
ORDER BY avg_account_balance DESC
LIMIT 10;
