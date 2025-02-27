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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
TopPricedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
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
        p.rank <= 5
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.supplier_name,
    tp.nation_name,
    tp.region_name,
    tp.p_retailprice,
    tp.p_comment,
    CONCAT('Part: ', tp.p_name, ' | Supplier: ', tp.supplier_name, ', Nation: ', tp.nation_name, ', Region: ', tp.region_name, ' | Price: $', FORMAT(tp.p_retailprice, 2)) AS detail
FROM 
    TopPricedParts tp
ORDER BY 
    tp.p_retailprice DESC;
