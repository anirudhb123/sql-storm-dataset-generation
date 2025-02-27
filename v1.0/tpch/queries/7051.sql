WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
    ORDER BY 
        total_cost DESC
    LIMIT 10
),
SupplierNation AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name, 
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_brand, 
    sn.s_name AS supplier_name, 
    sn.n_name AS nation, 
    rp.total_cost 
FROM 
    RankedParts rp
JOIN 
    SupplierNation sn ON rp.p_partkey IN (
        SELECT 
            ps.ps_partkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_suppkey = sn.s_suppkey
    )
ORDER BY 
    rp.total_cost DESC
LIMIT 5;
