WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name,
           CONCAT(s.s_name, ' from ', n.n_name, ' located at ', s.s_address) AS supplier_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartAggregate AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           STRING_AGG(CONCAT(sd.supplier_info, ' (Qty: ', ps.ps_availqty, ')'), ', ') AS suppliers_details
    FROM partsupp ps
    JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    GROUP BY ps.ps_partkey
),
FinalOutput AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, pa.total_avail_qty, pa.supplier_count,
           pa.suppliers_details,
           CASE
               WHEN pa.total_avail_qty > 100 THEN 'Sufficient Stock'
               ELSE 'Low Stock'
           END AS stock_status
    FROM part p
    JOIN PartAggregate pa ON p.p_partkey = pa.ps_partkey
)
SELECT p_partkey, p_name, p_brand, p_type, total_avail_qty, supplier_count, suppliers_details, stock_status
FROM FinalOutput
WHERE stock_status = 'Low Stock'
ORDER BY total_avail_qty ASC, p_name;
