
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        CONCAT(s.s_name, ' - ', n.n_name) AS supplier_nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        STRING_AGG(DISTINCT CONCAT(ps.ps_suppkey, ' (', SUPPLIERS.supplier_nation, ')'), ', ') AS supplier_list
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN SupplierInfo SUPPLIERS ON ps.ps_suppkey = SUPPLIERS.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
)
SELECT 
    p.p_name,
    p.p_retailprice,
    LENGTH(p.p_comment) AS comment_length,
    (SELECT COUNT(DISTINCT ps.ps_suppkey) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS supplier_count,
    p.p_container,
    ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS rank
FROM PartDetails p
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
ORDER BY 
    LENGTH(p.p_comment) DESC, p.p_retailprice DESC;
