
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size > 20
),
TopParts AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        rp.p_name AS part_name,
        rp.p_retailprice
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rp.price_rank <= 5
)
SELECT 
    region_name, 
    nation_name, 
    supplier_name, 
    ARRAY_AGG(part_name) AS top_parts
FROM 
    TopParts
GROUP BY 
    region_name, 
    nation_name, 
    supplier_name
ORDER BY 
    region_name, 
    nation_name, 
    supplier_name;
