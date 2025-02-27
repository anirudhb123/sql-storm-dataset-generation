WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS SuppRank
    FROM supplier s
), 
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice > 100 THEN 'High Value'
            WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS Valuation
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS TotalSales,
        COUNT(DISTINCT li.l_partkey) AS UniquePartsCount
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY o.o_orderkey
)

SELECT 
    r.n_name AS SupplierNation,
    hvp.Valuation,
    COUNT(DISTINCT hs.s_suppkey) AS SupplierCount,
    AVG(od.TotalSales) AS AvgSales,
    SUM(CASE 
        WHEN od.UniquePartsCount > 5 THEN od.TotalSales
        ELSE 0 
    END) AS SalesAboveFiveUniqueParts,
    MAX(od.TotalSales) AS MaxOrderSales,
    SUM(CASE WHEN hvp.p_retailprice IS NULL THEN 1 ELSE 0 END) AS NullRetailPriceCount
FROM RankedSuppliers hs
JOIN nation r ON hs.s_nationkey = r.n_nationkey
LEFT JOIN HighValueParts hvp ON hvp.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps
    WHERE ps.ps_availqty > 0 AND ps.ps_supplycost > (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
)
JOIN OrderDetails od ON od.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
)
GROUP BY r.n_name, hvp.Valuation
HAVING COUNT(DISTINCT hs.s_suppkey) > 1
ORDER BY SupplierNation, hvp.Valuation DESC;
