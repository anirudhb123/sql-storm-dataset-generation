WITH RankedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        ps.ps_availqty,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
        s.s_name AS supplier_name,
        n.n_name AS nation_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_type LIKE '%brass%'
        AND s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2
            WHERE s2.s_nationkey = n.n_nationkey
        )
),
TopProducts AS (
    SELECT 
        r.p_partkey,
        r.p_name,
        r.p_brand,
        r.price_rank,
        r.supplier_name,
        r.nation_name
    FROM 
        RankedProducts r
    WHERE 
        r.price_rank <= 5
)
SELECT 
    tp.p_brand,
    COUNT(tp.p_partkey) AS number_of_top_products,
    STRING_AGG(CONCAT(tp.p_name, ' (', tp.supplier_name, ', ', tp.nation_name, ')'), ', ') AS top_product_details
FROM 
    TopProducts tp
GROUP BY 
    tp.p_brand
ORDER BY 
    number_of_top_products DESC;
