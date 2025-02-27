WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS RankByBalance
    FROM supplier s
),
AvailableParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        CASE 
            WHEN ps.ps_availqty IS NULL THEN 0 
            ELSE ps.ps_availqty 
        END AS AdjustedAvailableQty
    FROM partsupp ps
    WHERE ps.ps_supplycost > 0
),
LargestCustomer AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalSales
    FROM customer c 
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 100000
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        MAX(l.l_extendedprice) AS MaxExtendedPrice
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0.0 AND 0.25
    GROUP BY l.l_orderkey, l.l_partkey, l.l_suppkey
)
SELECT 
    p.p_name,
    r.r_name AS RegionName,
    COUNT(DISTINCT c.c_custkey) AS CustomerCount,
    AVG(ls.MaxExtendedPrice) AS AvgMaxExtendedPrice,
    COALESCE(NULLIF(SUM(s.s_acctbal), 0), (SELECT AVG(s2.s_acctbal) FROM supplier s2)) AS TotalSupplierBalance
FROM part p
LEFT JOIN AvailableParts ap ON p.p_partkey = ap.ps_partkey
LEFT JOIN RankedSuppliers s ON ap.ps_suppkey = s.s_suppkey AND s.RankByBalance = 1
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN FilteredLineItems ls ON ls.l_suppkey = s.s_suppkey
JOIN LargestCustomer lc ON lc.c_custkey = s.s_suppkey
WHERE p.p_size > 10
  AND (s.s_name IS NOT DISTINCT FROM lc.c_custkey OR lc.TotalSales IS NOT NULL)
GROUP BY p.p_name, r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 0
ORDER BY RegionName, CustomerCount DESC, AvgMaxExtendedPrice DESC;
