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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn_highest_price,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_size ASC) AS rn_smallest_size
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS supplier_nation,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus,
        l.l_shipdate,
        l.l_commitdate,
        l.l_receiptdate,
        l.l_shipinstruct,
        l.l_shipmode,
        l.l_comment
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'Y'
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sd.s_name AS supplier_name,
    sd.s_address AS supplier_address,
    ld.l_quantity,
    ld.l_extendedprice,
    ld.l_discount,
    ld.l_shipdate,
    ld.l_commitdate
FROM 
    RankedParts rp
JOIN 
    SupplierDetails sd ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey LIMIT 1)
JOIN 
    LineItemDetails ld ON ld.l_partkey = rp.p_partkey
WHERE 
    rp.rn_highest_price = 1 OR rp.rn_smallest_size = 1
ORDER BY 
    rp.p_retailprice DESC, ld.l_shipdate;
