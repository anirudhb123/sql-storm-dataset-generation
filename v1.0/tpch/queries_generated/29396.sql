WITH ranked_parts AS (
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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10
),
filtered_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone 
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
nation_part_info AS (
    SELECT 
        n.n_name AS nation_name,
        np.p_name AS part_name,
        np.p_retailprice
    FROM 
        nation n
    JOIN 
        filtered_suppliers fs ON n.n_nationkey = fs.s_nationkey
    JOIN 
        partsupp ps ON fs.s_suppkey = ps.ps_suppkey
    JOIN 
        ranked_parts np ON ps.ps_partkey = np.p_partkey
)
SELECT 
    nation_name, 
    part_name, 
    AVG(p_retailprice) AS avg_part_price
FROM 
    nation_part_info
GROUP BY 
    nation_name, 
    part_name
HAVING 
    AVG(p_retailprice) > 100
ORDER BY 
    nation_name, 
    avg_part_price DESC;
