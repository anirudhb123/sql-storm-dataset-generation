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
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.part_count,
        s.total_supply_cost,
        s.avg_acct_balance,
        ROW_NUMBER() OVER (ORDER BY s.total_supply_cost DESC) AS rnk
    FROM 
        SupplierStats s
)

SELECT 
    tp.s_suppkey,
    tp.s_name,
    tp.part_count,
    tp.total_supply_cost,
    tp.avg_acct_balance,
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_retailprice
FROM 
    TopSuppliers tp
JOIN 
    RankedParts rp ON tp.part_count > 0 AND tp.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey)
WHERE 
    tp.rnk <= 10 
    AND rp.rnk <= 5
ORDER BY 
    tp.total_supply_cost DESC, 
    rp.p_retailprice DESC;
