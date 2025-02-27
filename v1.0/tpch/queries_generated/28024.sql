WITH FilteredParts AS (
    SELECT p_partkey, 
           p_name, 
           p_size, 
           p_retailprice, 
           p_comment,
           LENGTH(p_name) AS name_length,
           UPPER(p_name) AS name_upper,
           LOWER(p_comment) AS comment_lower
    FROM part
    WHERE p_size BETWEEN 10 AND 30
      AND p_retailprice > 50.00
), SupplierDetails AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_address,
           s.nationkey,
           s.s_phone,
           s.s_acctbal,
           SUBSTRING(s.s_comment, 1, 20) AS short_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name LIKE 'United%'
), OrderAggregation AS (
    SELECT o.o_orderkey,
           COUNT(l.l_orderkey) AS lineitem_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT fp.p_partkey, 
       fp.p_name, 
       fp.p_size,
       fp.p_retailprice, 
       sd.s_name AS supplier_name, 
       sd.short_comment,
       oa.lineitem_count,
       oa.total_revenue,
       CONCAT(fp.name_upper, ' - ', sd.s_name) AS combined_identifier
FROM FilteredParts fp
JOIN SupplierDetails sd ON fp.p_partkey = sd.s_suppkey
LEFT JOIN OrderAggregation oa ON oa.o_orderkey = fp.p_partkey
ORDER BY fp.p_retailprice DESC, oa.total_revenue DESC;
