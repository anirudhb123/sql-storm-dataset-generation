WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) as SupplyRank,
        p.p_partkey,
        p.p_retailprice,
        p.p_type
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
), ExpensiveParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '1995-01-01' AND '1996-12-31'
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
), SupplierDetails AS (
    SELECT 
        r.r_name AS RegionName,
        n.n_name AS NationName,
        s.s_name AS SupplierName,
        COUNT(DISTINCT ps.ps_partkey) AS NumberOfPartsSupplied
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name, n.n_name, s.s_name
)
SELECT 
    ep.p_partkey,
    ep.p_name,
    ep.p_retailprice,
    COALESCE(rs.s_name, 'No Supplier') AS SupplierName,
    d.RegionName,
    d.NationName,
    d.NumberOfPartsSupplied,
    ep.TotalSales,
    CASE 
        WHEN ep.TotalSales > 100000 THEN 'High'
        WHEN ep.TotalSales BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS SalesCategory
FROM ExpensiveParts ep
LEFT JOIN RankedSuppliers rs ON ep.p_partkey = rs.p_partkey AND rs.SupplyRank = 1
LEFT JOIN SupplierDetails d ON rs.s_suppkey = d.SupplierName
WHERE ep.p_type LIKE 'MFGR#1%'
  AND (ep.p_retailprice IS NOT NULL AND ep.p_retailprice > 0)
  AND (SELECT COUNT(*) FROM customer c WHERE c.c_acctbal IS NULL OR c.c_acctbal < 0) > 10
ORDER BY ep.TotalSales DESC, rs.s_name;
