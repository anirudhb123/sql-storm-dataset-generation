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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_comment LIKE '%extra%'
),
SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, s.s_address, n.n_name, r.r_name
    HAVING COUNT(DISTINCT ps.ps_partkey) > 1
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
    rp.p_comment,
    sd.s_name,
    sd.s_address,
    sd.nation_name,
    sd.region_name,
    sd.num_parts
FROM RankedParts rp
JOIN SupplierDetails sd ON rp.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_name LIKE '%' || rp.p_brand || '%'
)
WHERE rp.rn <= 5
ORDER BY rp.p_brand, rp.p_retailprice DESC;
