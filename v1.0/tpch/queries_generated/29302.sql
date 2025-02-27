WITH RankedParts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_mfgr,
           p.p_brand,
           p.p_type,
           p.p_size,
           p.p_container,
           p.p_retailprice,
           p.p_comment,
           RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price,
           LENGTH(p.p_comment) AS comment_length
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 30
), FilteredSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_address, 
           s.s_nationkey, 
           s.s_phone, 
           s.s_acctbal, 
           s.s_comment, 
           SUBSTRING(s.s_comment, 1, 50) AS short_comment
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
), JoinData AS (
    SELECT rp.p_partkey, 
           rp.p_name, 
           rp.p_brand, 
           rp.rank_price, 
           fs.s_suppkey, 
           fs.s_name, 
           fs.short_comment
    FROM RankedParts rp
    JOIN FilteredSuppliers fs ON rp.p_partkey = fs.s_suppkey -- Adjusting for realistic join
)
SELECT jd.p_partkey,
       jd.p_name,
       jd.p_brand,
       jd.rank_price,
       COUNT(jd.s_suppkey) AS supplier_count,
       STRING_AGG(jd.short_comment, '; ') AS comments_summary
FROM JoinData jd
GROUP BY jd.p_partkey, jd.p_name, jd.p_brand, jd.rank_price
HAVING COUNT(jd.s_suppkey) > 1
ORDER BY jd.rank_price DESC, jd.p_name ASC
LIMIT 100;
