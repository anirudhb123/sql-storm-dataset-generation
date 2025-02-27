WITH FilteredPart AS (
    SELECT p_partkey, p_name, p_brand, p_type
    FROM part
    WHERE p_retailprice > 100.00
),
SupplierSummary AS (
    SELECT s.n_nationkey, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.n_nationkey
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT r.r_name, COUNT(DISTINCT fp.p_partkey) AS part_count, COALESCE(SUM(ss.supplier_count), 0) AS total_suppliers, COALESCE(SUM(od.total_revenue), 0) AS total_revenue
FROM region r
LEFT JOIN FilteredPart fp ON fp.p_brand LIKE 'Brand%'
LEFT JOIN SupplierSummary ss ON ss.n_nationkey = r.r_regionkey
LEFT JOIN OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
GROUP BY r.r_name
ORDER BY r.r_name;
