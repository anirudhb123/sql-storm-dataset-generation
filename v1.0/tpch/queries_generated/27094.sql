WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, n.n_name AS nation_name, s.s_address, s.s_phone, 
           s.s_acctbal, s.s_comment,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueSuppliers AS (
    SELECT * FROM SupplierDetails WHERE rank <= 5
),
PartAndComments AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, p.p_comment,
           LENGTH(p.p_comment) AS comment_length
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
      AND p.p_comment IS NOT NULL
),
SupplierPartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, p.p_comment, s.s_name, s.s_address
    FROM PartAndComments p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.comment_length > 20
)
SELECT 
    hvs.s_name AS supplier_name,
    hvs.s_address AS supplier_address,
    pp.p_name AS part_name,
    pp.p_brand AS part_brand,
    pp.p_retailprice AS part_retail_price,
    pp.p_comment AS part_comment,
    COUNT(*) OVER (PARTITION BY hvs.s_name) AS total_parts
FROM HighValueSuppliers hvs
JOIN SupplierPartDetails pp ON hvs.s_suppkey = pp.s_suppkey
ORDER BY hvs.s_name, pp.p_retailprice DESC;
