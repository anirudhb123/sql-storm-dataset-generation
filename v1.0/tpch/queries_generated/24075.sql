WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_brand,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as BrandRank
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'NO BALANCE' 
            ELSE 'BALANCED' 
        END AS BalanceStatus
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_custkey
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS LineTotal,
        MAX(l.l_shipdate) AS LastShipDate
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    r.RegionName,
    AVG(RandomPrice) AS AvgPartPrice,
    COUNT(DISTINCT o.o_orderkey) AS DistinctOrderCount,
    SUM(COALESCE(l.LineTotal, 0)) AS TotalLineItems,
    (SELECT COUNT(*) FROM RankedParts rp WHERE rp.BrandRank <= 3) AS TopBrandsCount
FROM ( 
    SELECT 
        n.n_regionkey,
        r.r_name AS RegionName,
        SUM(p.p_retailprice) AS RandomPrice
    FROM region r
    JOIN nation n ON n.n_regionkey = r.r_regionkey
    LEFT JOIN RankedParts rp ON rp.p_brand = n.n_name
    GROUP BY n.n_regionkey, r.r_name
) AS r
JOIN HighValueOrders o ON o.o_custkey IN (
    SELECT c.c_custkey 
    FROM customer c WHERE c.c_acctbal IS NOT NULL 
      AND LENGTH(c.c_name) > 5
)
LEFT JOIN LineItemSummary l ON l.l_orderkey = o.o_orderkey
GROUP BY r.RegionName
HAVING AVG(RandomPrice) > 500
ORDER BY DistinctOrderCount DESC
WITH ROLLUP;
