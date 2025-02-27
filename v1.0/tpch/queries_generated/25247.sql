SELECT
    CONCAT('Supplier Name: ', s.s_name, ' | Part Name: ', p.p_name, ' | Available Quantity: ', ps.ps_availqty, ' | Supply Cost: ', ps.ps_supplycost) AS SupplierPartInfo,
    SUBSTRING_INDEX(s.s_comment, ' ', 5) AS ShortComment,
    LENGTH(p.p_comment) AS CommentLength,
    TRIM(UPPER(p.p_type)) AS FormattedPartType
FROM
    partsupp ps
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    ps.ps_availqty > 10 
    AND s.s_acctbal > 1000.00
ORDER BY
    p.p_brand DESC,
    LENGTH(s.s_name) ASC
LIMIT 50;
