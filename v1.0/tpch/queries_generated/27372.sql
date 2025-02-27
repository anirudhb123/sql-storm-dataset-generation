WITH ranked_partitions AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY SUBSTR(p.p_name, 1, 1) ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100
), benchmarks AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        rp.p_name AS part_name,
        rp.p_retailprice,
        rp.p_comment
    FROM 
        ranked_partitions rp
    JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    STRING_AGG(CONCAT(part_name, ' (Price: ', p_retailprice, ', Comment: ', p_comment, ')'), '; ') AS part_details
FROM 
    benchmarks
WHERE 
    price_rank <= 5
GROUP BY 
    region_name, nation_name, supplier_name
ORDER BY 
    region_name, nation_name, supplier_name;
