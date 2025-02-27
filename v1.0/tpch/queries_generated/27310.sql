WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           CASE 
               WHEN LENGTH(p.p_name) > 25 THEN SUBSTRING(p.p_name FROM 1 FOR 25) || '...'
               ELSE p.p_name 
           END AS ShortenedName,
           COUNT(ps.ps_partkey) AS SupplyCount
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
SupplierDetails AS (
    SELECT s.s_name, s.s_address, n.n_name AS NationName
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
CustomerStats AS (
    SELECT c.c_name, c.c_acctbal, 
           CASE 
               WHEN LENGTH(c.c_comment) > 50 THEN SUBSTRING(c.c_comment FROM 1 FOR 50) || '...'
               ELSE c.c_comment 
           END AS ShortComment
    FROM customer c
    WHERE c.c_acctbal > 1000
)
SELECT rp.ShortenedName, rp.p_brand, rp.SupplyCount, 
       sd.s_name, sd.s_address, sd.NationName, 
       cs.c_name, cs.c_acctbal, cs.ShortComment
FROM RankedParts rp
JOIN SupplierDetails sd ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0 LIMIT 1)
JOIN CustomerStats cs ON cs.c_acctbal BETWEEN 1000 AND 5000
ORDER BY rp.SupplyCount DESC, cs.c_acctbal DESC;
