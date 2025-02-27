WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_nationkey
),
TotalSales AS (
    SELECT c.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
RankedSales AS (
    SELECT ts.c_custkey, ts.total_spent,
           RANK() OVER (ORDER BY ts.total_spent DESC) AS sales_rank
    FROM TotalSales ts
),
SupplierPartCount AS (
    SELECT ps.ps_suppkey, COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
)
SELECT 
    c.c_name, 
    c.c_address, 
    r.r_name, 
    sh.level AS supplier_level,
    COALESCE(sp.total_parts, 0) AS total_parts,
    COALESCE(rs.total_spent, 0) AS total_spent,
    CASE 
        WHEN rs.sales_rank IS NULL THEN 'No Sales'
        ELSE 'Ranked ' || CAST(rs.sales_rank AS VARCHAR)
    END AS sales_status
FROM customer c
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN RankedSales rs ON c.c_custkey = rs.c_custkey
LEFT JOIN SupplierPartCount sp ON sp.ps_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
    WHERE s.s_nationkey = c.c_nationkey
)
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey 
WHERE COALESCE(rs.total_spent, 0) > 1000
ORDER BY total_spent DESC NULLS LAST;
