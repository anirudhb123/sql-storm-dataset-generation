WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
AggregateOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' 
    GROUP BY o.o_orderkey
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           CASE 
               WHEN p.p_size > 20 THEN 'Large'
               WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
               ELSE 'Small' 
           END AS size_category
    FROM part p
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2
    )
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT r.c_custkey) AS total_customers,
    SUM(a.total_revenue) AS total_revenues,
    f.size_category,
    MAX(CASE WHEN rh.level IS NOT NULL THEN rh.s_name ELSE 'Top Supplier Not Found' END) AS top_supplier
FROM nation n
LEFT JOIN RankedCustomers r ON n.n_nationkey = r.c_nationkey 
LEFT JOIN AggregateOrders a ON r.c_custkey = a.o_orderkey
LEFT JOIN FilteredParts f ON f.p_partkey = (SELECT ps.ps_partkey 
                                             FROM partsupp ps 
                                             WHERE ps.ps_suppkey = 
                                                 (SELECT s.s_suppkey 
                                                  FROM supplier s 
                                                  WHERE s.s_nationkey = n.n_nationkey 
                                                  LIMIT 1))
LEFT JOIN SupplierHierarchy rh ON rh.s_nationkey = n.n_nationkey
GROUP BY n.n_name, f.size_category
HAVING COUNT(DISTINCT r.c_custkey) > 10
ORDER BY total_revenues DESC, n.n_name;
