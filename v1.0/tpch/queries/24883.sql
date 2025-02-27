WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_comment, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2
        WHERE s2.s_acctbal IS NOT NULL
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_comment, s.s_acctbal, h.level + 1
    FROM supplier s
    JOIN SupplierHierarchy h ON s.s_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name = 'GERMANY'
    )
    WHERE h.level < 3
),
OrderYT AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 1000
),
LineItemSummary AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING COUNT(DISTINCT l.l_partkey) > 2
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_size
    FROM part p
    WHERE p.p_retailprice BETWEEN 10 AND 100 
      AND p.p_size IS NOT NULL
      AND LENGTH(p.p_name) BETWEEN 3 AND 25
)
SELECT 
    r.r_name,
    COALESCE(SUM(s.s_acctbal), 0) AS total_acctbal,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.total_revenue) AS avg_revenue,
    SUM(CASE WHEN l.supplier_count > 1 THEN 1 ELSE 0 END) AS multi_supplier_orders
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN OrderYT o ON s.s_suppkey = o.o_orderkey
LEFT JOIN LineItemSummary l ON o.o_orderkey = l.l_orderkey
WHERE
    r.r_name NOT LIKE '%east%'
    AND COALESCE(s.s_acctbal, 0) <> 0
    AND EXISTS (
        SELECT 1
        FROM FilteredParts fp
        WHERE fp.p_partkey IN (
            SELECT ps.ps_partkey 
            FROM partsupp ps 
            WHERE ps.ps_suppkey = s.s_suppkey
        )
    )
GROUP BY r.r_name
ORDER BY total_acctbal DESC, avg_revenue ASC
LIMIT 10;
