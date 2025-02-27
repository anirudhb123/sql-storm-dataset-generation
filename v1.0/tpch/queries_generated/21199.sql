WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, s_acctbal, 0 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rnk
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
      AND c.c_acctbal IN (SELECT DISTINCT ps_supplycost FROM partsupp WHERE ps_availqty >
          (SELECT MAX(ps_availqty) FROM partsupp) / 2)
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           COUNT(l.l_orderkey) AS total_items, 
           RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey
),
Combination AS (
    SELECT sh.s_name, hv.c_name, os.total_revenue, sh.hierarchy_level
    FROM SupplierHierarchy sh
    FULL OUTER JOIN HighValueCustomers hv ON sh.s_nationkey = hv.c_custkey
    FULL OUTER JOIN OrderStats os ON hv.c_custkey = os.o_orderkey
)
SELECT 
    COALESCE(s_name, 'Unknown Supplier') AS supplier,
    COALESCE(c_name, 'Unknown Customer') AS customer,
    COALESCE(total_revenue, 0) AS revenue,
    hierarchy_level
FROM Combination
WHERE total_revenue > (SELECT AVG(total_revenue) FROM OrderStats)
   OR hierarchy_level IS NULL
ORDER BY revenue DESC NULLS LAST, supplier ASC;
