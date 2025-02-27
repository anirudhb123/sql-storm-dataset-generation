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
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as price_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
), SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        n.n_name AS nation_name, 
        COUNT(ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
), SelectedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        s.parts_supplied
    FROM 
        RankedParts p
    JOIN 
        SupplierInfo s ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey ORDER BY ps.ps_supplycost ASC LIMIT 1)
    WHERE 
        p.price_rank = 1
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    s.parts_supplied
FROM 
    SelectedParts p
JOIN 
    supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey ORDER BY ps.ps_supplycost DESC LIMIT 1)
WHERE 
    s.parts_supplied > 5
ORDER BY 
    p.p_brand, p.p_partkey;
