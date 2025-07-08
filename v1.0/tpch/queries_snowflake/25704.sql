
WITH RankedParts AS (
    SELECT 
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
        p.p_partkey
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_size BETWEEN 10 AND 20)
),
SupplierParts AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        rp.p_name,
        rp.price_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT sp.s_name) AS supplier_count,
    AVG(sp.price_rank) AS average_price_rank,
    LISTAGG(sp.p_name, ', ') WITHIN GROUP (ORDER BY sp.p_name) AS part_names
FROM 
    SupplierParts sp
JOIN 
    nation n ON sp.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    supplier_count DESC, average_price_rank ASC;
