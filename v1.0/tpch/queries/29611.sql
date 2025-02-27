WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    pd.nation_name,
    pd.region_name,
    COUNT(pd.p_partkey) AS total_parts,
    AVG(pd.p_retailprice) AS avg_price,
    SUM(pd.p_retailprice) AS total_retail_value,
    STRING_AGG(pd.p_name || ' (Brand: ' || pd.p_brand || ', Type: ' || pd.p_type || ')', ', ') AS part_names
FROM PartDetails pd
WHERE pd.rank <= 5
GROUP BY pd.nation_name, pd.region_name
ORDER BY pd.nation_name, pd.region_name;
