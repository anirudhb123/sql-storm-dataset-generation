WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS part_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.total_available_qty,
        rp.total_supply_cost
    FROM 
        RankedParts rp
    WHERE 
        rp.part_rank <= 5
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        n.n_name AS nation_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.p_brand,
    tp.total_available_qty,
    tp.total_supply_cost,
    sd.s_name AS supplier_name,
    sd.nation_name,
    sd.s_acctbal AS supplier_acctbal
FROM 
    TopParts tp
JOIN 
    SupplierDetails sd ON sd.s_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey = tp.p_partkey
    )
ORDER BY 
    tp.total_supply_cost DESC;
