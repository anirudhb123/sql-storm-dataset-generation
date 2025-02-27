WITH PartDetails AS (
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
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty,
        CONCAT(p.p_name, ' from ', p.p_mfgr, ' - ', p.p_comment) AS extended_info
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 50.00
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        CONCAT(s.s_name, ' in ', s.s_address) AS supplier_info
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000.00
),
RegionInfo AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.extended_info,
    sd.supplier_info,
    rd.r_name,
    rd.nation_count,
    pd.supplier_count,
    pd.total_supply_cost,
    pd.avg_avail_qty
FROM 
    PartDetails pd
JOIN 
    SupplierDetails sd ON pd.supplier_count > 0
JOIN 
    RegionInfo rd ON pd.p_partkey % rd.nation_count = 0
ORDER BY 
    pd.p_retailprice DESC,
    sd.s_acctbal ASC;
