WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.hierarchy_level < 5
),
PartSales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, ps.total_sales,
           RANK() OVER (ORDER BY ps.total_sales DESC) AS sales_rank
    FROM PartSales ps
    JOIN part p ON ps.p_partkey = p.p_partkey
)
SELECT r.r_name, n.n_name, s.s_name, rp.p_name, rp.total_sales
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN RankedParts rp ON s.s_suppkey = (SELECT ps.ps_suppkey
                                            FROM partsupp ps 
                                            WHERE ps.ps_partkey = rp.p_partkey
                                            ORDER BY ps.ps_supplycost ASC
                                            LIMIT 1)
WHERE rp.sales_rank <= 5
AND n.n_name IS NOT NULL
ORDER BY r.r_name, n.n_name, rp.total_sales DESC;
