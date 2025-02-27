WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS RankPrice
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 20
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(s.s_acctbal) AS avg_balance,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name, 
        r.r_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY n.n_name) AS RegionRank
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rss.avg_balance,
    rss.part_count,
    CASE 
        WHEN rss.total_available IS NULL THEN 'No supply available'
        ELSE CAST(rss.total_available AS VARCHAR) 
    END AS available_status,
    nrr.r_name AS region_name,
    nrr.RegionRank
FROM RankedParts rp
LEFT JOIN SupplierStats rss ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_name LIKE 'Supplier%'))
LEFT JOIN NationRegion nrr ON nrr.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name = 'SupplierX') 
WHERE rp.RankPrice <= 5
ORDER BY rp.p_retailprice DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM orders WHERE o_orderstatus = 'F') % 100;
