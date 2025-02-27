SELECT 
    CONCAT('Part: ', p_name, ' - Manufacturer: ', p_mfgr) AS part_details,
    COUNT(DISTINCT s_suppkey) AS supplier_count,
    SUM(ps_availqty) AS total_available_quantity,
    AVG(s_acctbal) AS average_supplier_balance,
    STRING_AGG(DISTINCT n_name, ', ') AS associated_nations
FROM
    part
JOIN
    partsupp ON p_partkey = ps_partkey
JOIN
    supplier ON ps_suppkey = s_suppkey
JOIN
    nation ON s_nationkey = n_nationkey
WHERE
    p_retailprice > 50.00 AND
    LENGTH(p_comment) >= 10
GROUP BY 
    p_partkey, p_name, p_mfgr
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
