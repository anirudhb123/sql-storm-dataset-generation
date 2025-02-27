WITH RECURSIVE CustomerAnalytics AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, 
           1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_custkey != c.c_custkey)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, 
           ca.level + 1
    FROM customer c
    JOIN CustomerAnalytics ca ON c.c_nationkey = ca.c_nationkey
    WHERE ca.level < 3
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
SupplierPerformance AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
RankedLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT c.c_name, c.c_acctbal, COALESCE(os.total_spent, 0) AS total_order_value, 
       COALESCE(sp.total_supply_cost, 0) AS supplier_cost,
       RANK() OVER (ORDER BY c.c_acctbal DESC) AS account_rank,
       COUNT(DISTINCT li.l_orderkey) AS total_orders
FROM CustomerAnalytics c
LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
LEFT JOIN SupplierPerformance sp ON sp.p_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
)
LEFT JOIN RankedLineItems li ON li.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o 
    WHERE o.o_custkey = c.c_custkey
)
WHERE c.c_acctbal IS NOT NULL
GROUP BY c.c_name, c.c_acctbal, os.total_spent, sp.total_supply_cost
HAVING COUNT(DISTINCT li.l_orderkey) > 5
ORDER BY c.c_acctbal DESC, total_order_value DESC;
