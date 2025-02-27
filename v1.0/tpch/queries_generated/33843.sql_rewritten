WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS row_num
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT
    r.r_name,
    COUNT(DISTINCT ns.n_nationkey) AS nation_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    CASE 
        WHEN MAX(l.l_shipdate) < cast('1998-10-01' as date) - INTERVAL '1 year' THEN 'Inactive'
        ELSE 'Active'
    END AS supplier_status
FROM region r
LEFT JOIN nation ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = ns.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON l.l_partkey = ps.ps_partkey
JOIN TopCustomers tc ON tc.c_custkey = l.l_orderkey
WHERE r.r_name LIKE '%north%'
  AND l.l_returnflag = 'N'
  AND l.l_shipmode IN ('AIR', 'SHIP')
GROUP BY r.r_name
HAVING COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY total_revenue DESC
LIMIT 5;