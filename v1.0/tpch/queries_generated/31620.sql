WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal < sh.s_acctbal
    WHERE sh.level < 3
),
PartSupplierSales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_returnflag = 'N'
    GROUP BY p.p_partkey, p.p_name
),
RegionRanked AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT n.n_nationkey) DESC) as rank
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    p.ps_partkey,
    p.ps_availqty,
    p.ps_supplycost,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(su.level, -1) AS supplier_level,
    t.total_sales,
    r.r_name AS region_name,
    r.nation_count
FROM 
    partsupp p
LEFT JOIN 
    supplier s ON p.ps_suppkey = s.s_suppkey
LEFT JOIN 
    SupplierHierarchy su ON s.s_suppkey = su.s_suppkey
LEFT JOIN 
    PartSupplierSales t ON p.ps_partkey = t.p_partkey
CROSS JOIN 
    RegionRanked r
WHERE 
    (t.total_sales IS NOT NULL OR p.ps_availqty > 0)
    AND r.rank <= 5
ORDER BY 
    total_sales DESC NULLS LAST, p.ps_partkey;
