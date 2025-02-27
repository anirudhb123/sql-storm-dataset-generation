WITH SupplierInfo AS (
    SELECT s_name AS supplier_name,
           s_nationkey,
           CONCAT(s_name, ' - ', s_address) AS supplier_address,
           (SELECT COUNT(*) FROM partsupp WHERE ps_suppkey = s_suppkey) AS part_count
    FROM supplier
),
PartInfo AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_container,
           p.p_retailprice,
           CONCAT(p.p_name, ' ', p_container) AS part_full
    FROM part p
),
SalesInfo AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           h.n_name AS nation_name
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation h ON s.s_nationkey = h.n_nationkey
    GROUP BY o.o_orderkey, h.n_name
),
BenchmarkData AS (
    SELECT si.supplier_name,
           si.supplier_address,
           pi.part_full,
           si.part_count,
           si.s_nationkey,
           COALESCE(SUM(si.part_count) OVER (PARTITION BY si.s_nationkey), 0) AS total_parts_in_nation,
           COALESCE(SUM(si.part_count) OVER (PARTITION BY si.s_nationkey ORDER BY si.part_count DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), 0) AS ranked_parts,
           COALESCE(SUM(si.part_count) FILTER (WHERE si.part_count > 1), 0) AS multiple_parts_flag
    FROM SupplierInfo si
    JOIN PartInfo pi ON si.n_nationkey = (SELECT DISTINCT n_nationkey FROM supplier WHERE s_name = si.supplier_name)
)
SELECT bd.supplier_name,
       bd.part_full,
       bd.total_parts_in_nation,
       bd.ranked_parts,
       bd.multiple_parts_flag
FROM BenchmarkData bd
WHERE bd.multiple_parts_flag > 0
  AND bd.total_parts_in_nation > 1
ORDER BY bd.supplier_name, bd.part_full;
