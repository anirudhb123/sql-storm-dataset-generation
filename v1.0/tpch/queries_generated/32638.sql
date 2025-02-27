WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TotalSales AS (
    SELECT c.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_custkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedParts AS (
    SELECT pd.p_partkey, pd.p_name, pd.total_available,
           RANK() OVER (ORDER BY pd.total_available DESC) AS rank
    FROM PartDetails pd
)
SELECT r.r_name, 
       COUNT(DISTINCT sh.s_nationkey) AS supplier_count,
       SUM(ts.total_sales) AS total_sales,
       STRING_AGG(DISTINCT rp.p_name, ', ') AS top_parts
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN TotalSales ts ON s.s_nationkey = ts.c_custkey
LEFT JOIN RankedParts rp ON s.s_suppkey = rp.p_partkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING SUM(ts.total_sales) IS NOT NULL
ORDER BY SUM(ts.total_sales) DESC;
