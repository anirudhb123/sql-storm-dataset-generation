WITH RankedParts AS (
    SELECT 
        p_name,
        p_mfgr,
        p_size,
        p_container,
        ROW_NUMBER() OVER (PARTITION BY p_mfgr ORDER BY p_retailprice DESC) AS rn
    FROM 
        part
    WHERE 
        p_retailprice > (
            SELECT AVG(p_retailprice) 
            FROM part
        )
),
SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_phone,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > 1000.00
),
CombinedData AS (
    SELECT 
        rp.p_name, 
        rp.p_mfgr, 
        rp.p_size, 
        rp.p_container, 
        sd.s_name, 
        sd.s_phone, 
        sd.s_acctbal, 
        sd.nation_name,
        sd.region_name
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
)
SELECT 
    p_name,
    p_mfgr,
    p_size,
    p_container,
    COUNT(s_name) AS supplier_count,
    SUM(s_acctbal) AS total_supplier_balance,
    MAX(s_acctbal) AS max_supplier_balance,
    MIN(s_acctbal) AS min_supplier_balance
FROM 
    CombinedData
GROUP BY 
    p_name, 
    p_mfgr, 
    p_size, 
    p_container
HAVING 
    COUNT(s_name) > 1
ORDER BY 
    total_supplier_balance DESC, 
    p_name;
