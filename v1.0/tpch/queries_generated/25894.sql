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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS supply_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    rp.p_retailprice,
    sd.s_name AS supplier_name,
    sd.s_acctbal AS supplier_account_balance,
    sd.supply_count
FROM RankedParts rp
JOIN SupplierDetails sd ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey ORDER BY ps.ps_supplycost ASC LIMIT 1)
WHERE rp.rank_by_price <= 5
ORDER BY rp.p_brand, rp.p_retailprice DESC;
