WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           CAST(c.c_name AS VARCHAR(100)) AS full_name, 
           1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    
    UNION ALL
    
    SELECT ch.c_custkey, ch.c_name, ch.c_acctbal,
           CAST(CONCAT(ch.full_name, ' -> ', c.c_name) AS VARCHAR(100)), 
           ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_custkey = c.c_custkey
    WHERE ch.level < 3 AND c.c_acctbal IS NOT NULL
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopNations AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS cust_count
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(DISTINCT c.c_custkey) > 5
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT 
    ch.cust_key, ch.full_name, 
    np.n_name, 
    COALESCE(sp.total_cost, 0) AS supplier_cost, 
    SUM(os.revenue) AS total_revenue,
    RANK() OVER (PARTITION BY ch.level ORDER BY SUM(os.revenue) DESC) AS revenue_rank
FROM CustomerHierarchy ch
LEFT JOIN TopNations np ON ch.c_custkey = np.cust_count 
LEFT JOIN SupplierPerformance sp ON sp.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 50) LIMIT 1) 
LEFT JOIN OrderSummary os ON os.o_custkey = ch.c_custkey
GROUP BY ch.cust_key, ch.full_name, np.n_name, sp.total_cost, ch.level
HAVING SUM(os.revenue) > 1000
ORDER BY total_revenue DESC;
