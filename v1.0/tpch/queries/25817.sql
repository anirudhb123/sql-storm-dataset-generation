WITH part_brand_counts AS (
    SELECT 
        p_brand, 
        COUNT(*) AS brand_count, 
        SUM(p_retailprice) AS total_retailprice,
        STRING_AGG(p_name, ', ') AS part_names
    FROM part
    GROUP BY p_brand
),
supplier_counts AS (
    SELECT 
        n.n_name AS nation_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
)
SELECT 
    r.r_name AS region_name, 
    pb.p_brand, 
    pb.brand_count, 
    pb.total_retailprice,
    sc.supplier_count,
    LENGTH(pb.part_names) AS part_names_length,
    CASE 
        WHEN LENGTH(pb.part_names) > 100 THEN 'Long List'
        ELSE 'Short List'
    END AS part_name_length_category
FROM part_brand_counts pb
JOIN region r ON r.r_regionkey = (SELECT MAX(r_regionkey) FROM region) 
JOIN supplier_counts sc ON sc.nation_name = (SELECT n.n_name FROM nation n ORDER BY n.n_nationkey DESC LIMIT 1) 
ORDER BY pb.brand_count DESC, pb.total_retailprice DESC;