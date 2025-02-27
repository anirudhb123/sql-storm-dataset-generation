WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           NULL AS parent_suppkey
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           sh.s_suppkey AS parent_suppkey
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal > sh.s_acctbal AND sh.parent_suppkey IS NOT NULL
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
),
RegionSupplier AS (
    SELECT r.r_regionkey, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey
)
SELECT 
    r.r_name, 
    rs.supplier_count, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    AVG(os.total_sales) AS avg_order_value,
    COALESCE(SUM(sh.s_acctbal), 0) AS total_supplier_balance
FROM region r
LEFT JOIN RegionSupplier rs ON r.r_regionkey = rs.r_regionkey
LEFT JOIN orders o ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey LIMIT 1))
LEFT JOIN OrderStats os ON o.o_orderkey = os.o_orderkey
LEFT JOIN SupplierHierarchy sh ON rs.supplier_count > 10 AND sh.parent_suppkey IS NULL
GROUP BY r.r_name, rs.supplier_count
HAVING total_supplier_balance > 50000
ORDER BY avg_order_value DESC;
