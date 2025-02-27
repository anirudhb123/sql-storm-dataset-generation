
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 3
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '1997-01-01' 
      AND l.l_shipdate < DATE '1998-01-01' 
    GROUP BY o.o_orderkey
),
FilteredOrders AS (
    SELECT *
    FROM OrderDetails
    WHERE order_rank <= 10
),
SupplierStats AS (
    SELECT 
        sh.s_nationkey, 
        COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
        AVG(sh.level) AS avg_level
    FROM SupplierHierarchy sh
    GROUP BY sh.s_nationkey
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(ss.supplier_count, 0) AS total_suppliers,
    COALESCE(ss.avg_level, 0) AS average_supplier_level,
    fo.o_orderkey,
    fo.total_price,
    fo.distinct_parts
FROM nation n
LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN FilteredOrders fo ON fo.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_nationkey = n.n_nationkey
    )
)
WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'A%')
ORDER BY nation_name, total_price DESC;
