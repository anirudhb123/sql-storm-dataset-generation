WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2
    )
    UNION ALL
    SELECT sh.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM SupplierHierarchy sh
    JOIN supplier s ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > (
        SELECT MAX(s3.s_acctbal)
        FROM supplier s3
        WHERE s3.s_nationkey = (
            SELECT n.n_nationkey
            FROM nation n
            WHERE n.n_name = 'FRANCE'
        )
    )
),
OrdersWithDiscount AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerOrderCounts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment = 'BUILDING' 
    GROUP BY c.c_custkey
),
NationCounts AS (
    SELECT n.n_nationkey, COUNT(*) AS nation_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
),
PartSuppliers AS (
    SELECT p.p_partkey, p.p_name, COUNT(ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)

SELECT 
    COALESCE(sh.s_name, 'No Supplier') AS supplier_name,
    owd.total_price,
    cc.order_count,
    nc.nation_count,
    ps.p_name,
    ps.supplier_count
FROM SupplierHierarchy sh
FULL OUTER JOIN OrdersWithDiscount owd ON sh.s_suppkey = owd.o_orderkey
FULL OUTER JOIN CustomerOrderCounts cc ON cc.c_custkey = sh.s_suppkey
JOIN NationCounts nc ON nc.nation_count = cc.order_count
JOIN PartSuppliers ps ON ps.supplier_count = cc.order_count
WHERE (sh.level > 0 OR owd.total_price IS NOT NULL)
  AND (nc.nation_count IS NOT NULL AND nc.nation_count > 1)
ORDER BY ps.supplier_count DESC, owd.total_price DESC;
