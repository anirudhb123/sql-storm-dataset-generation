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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
)
SELECT 
    rp.p_brand, 
    COUNT(rp.p_partkey) AS part_count, 
    SUM(rp.p_retailprice) AS total_retail_price, 
    STRING_AGG(rp.p_name, ', ') AS part_names
FROM RankedParts rp
WHERE rp.price_rank <= 5
GROUP BY rp.p_brand
ORDER BY total_retail_price DESC;
