WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CONCAT(s.s_name, ' - Nation Key: ', s.s_nationkey) AS detailed_info,
           LENGTH(s.s_comment) AS comment_length
    FROM supplier s
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand,
           CONCAT(p.p_name, ' (', p.p_brand, ')') AS part_info,
           UPPER(p.p_comment) AS upper_comment
    FROM part p
),
LineItemDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, 
           CASE 
               WHEN l.l_returnflag = 'Y' THEN 'Returned' 
               ELSE 'Not Returned' 
           END AS return_status,
           CONCAT(l.l_linenumber, ': ', l.l_discount, '% off') AS discount_info
    FROM lineitem l
),
Benchmarking AS (
    SELECT sd.detailed_info, pd.part_info, 
           ld.return_status, ld.discount_info,
           sd.comment_length + LENGTH(pd.upper_comment) AS total_length
    FROM SupplierDetails sd
    JOIN PartDetails pd ON sd.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE') 
    JOIN LineItemDetails ld ON ld.l_suppkey = sd.s_suppkey
)
SELECT return_status, COUNT(*) AS total_count, AVG(total_length) AS average_length
FROM Benchmarking
GROUP BY return_status
ORDER BY total_count DESC;
