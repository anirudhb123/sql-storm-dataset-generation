WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
), 
OrderSummaries AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2022-01-01' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_custkey
), 
CustomerRanked AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        DENSE_RANK() OVER (ORDER BY SUM(os.total_revenue) DESC) AS revenue_rank
    FROM customer c
    JOIN OrderSummaries os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    COALESCE(AVG(cr.revenue_rank), 0) AS avg_revenue_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN CustomerRanked cr ON s.s_nationkey = cr.c_custkey
GROUP BY r.r_name
ORDER BY supplier_count DESC, avg_revenue_rank ASC;
