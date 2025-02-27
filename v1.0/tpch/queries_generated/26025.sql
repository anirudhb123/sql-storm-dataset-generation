WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SuppliersByRegion AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        n.n_name AS nation_name, 
        r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
StringProcessed AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        CONCAT('Supplier: ', sp.s_name, ' - Region: ', sb.region_name) AS SupplierRegionInfo
    FROM SuppliersByRegion sp
    JOIN (
        SELECT DISTINCT r.r_name 
        FROM region r
        WHERE r.r_name LIKE '%East%' OR r.r_name LIKE '%West%'
    ) sb ON sp.region_name = sb.r_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    rp.p_type,
    rp.p_size,
    rp.p_container,
    rp.p_retailprice,
    sp.SupplierRegionInfo
FROM RankedParts rp
JOIN StringProcessed sp ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sp.s_suppkey LIMIT 1)
WHERE rp.rnk <= 5
ORDER BY rp.p_retailprice DESC, sp.SupplierRegionInfo;
