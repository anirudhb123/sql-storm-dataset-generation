WITH SupplierRank AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supp_rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
PartsWithLowSuppliers AS (
    SELECT ps.ps_partkey, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING COUNT(DISTINCT ps.ps_suppkey) < 2
),
OrderDetails AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           SUM(od.order_value) AS customer_order_value
    FROM customer c
    LEFT JOIN OrderDetails od ON c.c_custkey = od.o_orderkey
    GROUP BY c.c_custkey
    HAVING SUM(od.order_value) IS NULL OR SUM(od.order_value) > 1000
)
SELECT DISTINCT n.n_name, 
                r.r_name, 
                p.p_name,
                COALESCE(sr.s_name, 'No Supplier') AS Supplier_Name,
                COALESCE(pw.supplier_count, 0) AS low_supplier_count
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN PartsWithLowSuppliers pw ON pw.ps_partkey = ANY (
    SELECT DISTINCT ps.ps_partkey FROM partsupp ps 
    WHERE ps.ps_suppkey IN (SELECT sr.s_suppkey FROM SupplierRank sr WHERE sr.supp_rank = 1)
)
JOIN part p ON p.p_partkey = pw.ps_partkey
LEFT JOIN SupplierRank sr ON sr.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = pw.ps_partkey
    LIMIT 1
)
WHERE n.n_nationkey NOT IN (SELECT n_nationkey FROM nation WHERE n_comment IS NULL)
AND (r.r_comment LIKE '%important%' OR r.r_comment IS NULL)
ORDER BY n.n_name, r.r_name DESC;
