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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS RankByPrice
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%widget%'
),
TopParts AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        p.p_name,
        p.p_retailprice,
        p.p_comment
    FROM 
        RankedParts p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        p.RankByPrice <= 5
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    COUNT(*) AS top_part_count,
    AVG(p_retailprice) AS avg_retail_price,
    STRING_AGG(CONCAT(p_name, ' (', p_retailprice, ')'), ', ') AS part_details
FROM 
    TopParts
GROUP BY 
    region_name, nation_name, supplier_name
ORDER BY 
    region_name, nation_name, top_part_count DESC;
