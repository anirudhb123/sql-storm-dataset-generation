WITH RankedSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierPartCount AS (
    SELECT ps.ps_partkey, COUNT(ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING COUNT(ps.ps_suppkey) > 3
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(spc.supplier_count, 0) AS supplier_count,
    COALESCE(rs.s_name, 'No Supplier') AS top_supplier,
    COALESCE(rs.s_acctbal, 0) AS top_supplier_acctbal,
    hvo.total_order_value
FROM part p
LEFT JOIN SupplierPartCount spc ON p.p_partkey = spc.ps_partkey
LEFT JOIN RankedSupplier rs ON p.p_partkey = rs.s_suppkey AND rs.rank = 1
LEFT JOIN HighValueOrders hvo ON hvo.o_orderkey = (SELECT l.l_orderkey
                                                    FROM lineitem l
                                                    WHERE l.l_partkey = p.p_partkey
                                                    LIMIT 1)
WHERE p.p_retailprice > 50
ORDER BY hvo.total_order_value DESC NULLS LAST, p.p_partkey;
