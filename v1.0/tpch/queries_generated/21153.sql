WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS supply_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        RANK() OVER (ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS nation_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 10
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    sr.s_name AS top_supplier,
    nr.n_name AS nation_name,
    nr.r_name AS region_name,
    rp.supplier_count,
    rp.supply_rank,
    tp.supplier_rank
FROM 
    RankedParts rp
LEFT JOIN 
    TopSuppliers tp ON rp.supplier_count > 0 AND rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = tp.s_suppkey)
LEFT JOIN 
    NationRegion nr ON tp.s_nationkey = nr.n_nationkey
INNER JOIN 
    supplier sr ON sr.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey)
WHERE 
    rp.supply_rank = 1 AND
    tp.supplier_rank <= 5 AND
    (rp.supplier_count IS NULL OR rp.supplier_count > 1)
ORDER BY 
    nr.nation_rank, rp.p_partkey;

