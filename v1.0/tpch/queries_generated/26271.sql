WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, 
           CONCAT(s.s_name, ' ', n.n_name) AS supplier_nation,
           SUBSTRING(s.s_comment, 1, 20) AS short_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, 
           p.p_comment, LENGTH(p.p_comment) AS comment_length
    FROM part p
),
OrderPartDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price,
           COUNT(DISTINCT l.l_partkey) AS part_count,
           STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')'), ', ') AS part_names
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN PartDetails p ON l.l_partkey = p.p_partkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
FinalBenchmark AS (
    SELECT sd.supplier_nation, 
           opd.part_count, 
           opd.total_lineitem_price,
           MIN(pd.comment_length) AS min_comment_length,
           MAX(pd.comment_length) AS max_comment_length,
           ROUND(AVG(pd.comment_length), 2) AS avg_comment_length
    FROM SupplierDetails sd
    JOIN OrderPartDetails opd ON sd.s_suppkey = opd.o_orderkey
    JOIN PartDetails pd ON pd.p_partkey IN (SELECT DISTINCT l.l_partkey
                                             FROM lineitem l
                                             JOIN orders o ON l.l_orderkey = o.o_orderkey
                                             WHERE o.o_totalprice = opd.o_totalprice)
    GROUP BY sd.supplier_nation, opd.part_count, opd.total_lineitem_price
)
SELECT supplier_nation, part_count, total_lineitem_price,
       min_comment_length, max_comment_length, avg_comment_length
FROM FinalBenchmark
ORDER BY total_lineitem_price DESC, part_count DESC;
