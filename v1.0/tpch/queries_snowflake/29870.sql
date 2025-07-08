
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
    SUBSTRING(p.p_name, 1, 20) AS short_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ' | Brand: ', p.p_brand) AS mfgr_brand,
    REPLACE(p.p_comment, 'unnecessary', 'essential') AS updated_comment,
    (SELECT COUNT(*) 
     FROM partsupp ps 
     WHERE ps.ps_partkey = p.p_partkey) AS supplier_count,
    (
        SELECT LISTAGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) 
        FROM supplier s 
        JOIN partsupp ps2 ON s.s_suppkey = ps2.ps_suppkey 
        WHERE ps2.ps_partkey = p.p_partkey
    ) AS supplier_names
FROM
    part p
WHERE
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2
    )
GROUP BY
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_size,
    p.p_container,
    p.p_retailprice,
    p.p_comment
ORDER BY
    p.p_name ASC
LIMIT 100;
