WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CONCAT(s.s_name, ' from ', n.n_name, ' in ', r.r_name) AS supplier_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT sd.s_suppkey, sd.s_name, sd.s_acctbal, sd.supplier_info,
           DENSE_RANK() OVER (ORDER BY sd.s_acctbal DESC) AS rank
    FROM SupplierDetails sd
),
PartAggregations AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty, 
           SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, pa.total_availqty, pa.total_supplycost,
           STRING_AGG(DISTINCT ts.supplier_info, '; ') AS suppliers
    FROM part p
    JOIN PartAggregations pa ON p.p_partkey = pa.ps_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
    GROUP BY p.p_partkey, p.p_name, pa.total_availqty, pa.total_supplycost
)
SELECT p.p_partkey, p.p_name, p.total_availqty, p.total_supplycost,
       p.suppliers, 
       CONCAT('Total Availability: ', p.total_availqty, ', Total Supply Cost: ', p.total_supplycost) AS processing_info
FROM PartSupplierInfo p
WHERE p.total_supplycost > 100.00
ORDER BY p.total_supplycost DESC;
