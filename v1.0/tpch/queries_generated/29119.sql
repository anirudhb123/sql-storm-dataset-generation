WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name,
           SUBSTRING(s.s_address, 1, 20) AS short_address,
           LENGTH(s.s_comment) AS comment_length
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartAggregation AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
LineItemSummary AS (
    SELECT l.l_partkey, AVG(l.l_extendedprice) AS avg_extended_price, 
           COUNT(*) AS order_count, 
           SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_partkey
)

SELECT 
    p.p_name, 
    sd.s_name, 
    sd.short_address, 
    sd.nation_name, 
    sd.region_name,
    pa.total_avail_qty,
    pa.unique_suppliers,
    lis.avg_extended_price,
    lis.order_count,
    lis.return_count
FROM part p
JOIN PartAggregation pa ON p.p_partkey = pa.ps_partkey
JOIN SupplierDetails sd ON sd.s_suppkey = (
    SELECT ps2.ps_suppkey
    FROM partsupp ps2
    WHERE ps2.ps_partkey = pa.ps_partkey
    ORDER BY ps2.ps_supplycost
    LIMIT 1
)
JOIN LineItemSummary lis ON lis.l_partkey = p.p_partkey
WHERE p.p_size > 10 AND sd.comment_length > 50
ORDER BY lis.avg_extended_price DESC, pa.total_avail_qty DESC;
