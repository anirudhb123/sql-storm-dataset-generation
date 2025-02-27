WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartStats AS (
    SELECT p.p_partkey, 
           p.p_name,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supplycost,
           SUM(CASE WHEN l.l_discount > 0.05 THEN l.l_extendedprice * l.l_discount ELSE 0 END) AS total_discounted_sales
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY p.p_partkey, p.p_name
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, ps.supplier_count, ps.avg_supplycost, ps.total_discounted_sales,
           RANK() OVER (ORDER BY ps.total_discounted_sales DESC) AS sales_rank
    FROM PartStats ps
    JOIN part p ON ps.p_partkey = p.p_partkey
    WHERE ps.supplier_count > 2
),
NationalAvg AS (
    SELECT n.n_nationkey, AVG(c.c_acctbal) AS avg_acctbal
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey
),
FinalStats AS (
    SELECT tp.p_partkey, tp.p_name, 
           COALESCE(sa.avg_acctbal, 0) AS avg_account_balance,
           tp.avg_supplycost, tp.total_discounted_sales
    FROM TopParts tp
    LEFT JOIN NationalAvg sa ON tp.supplier_count = sa.n_nationkey
)

SELECT f.p_partkey, f.p_name, 
       f.avg_account_balance,
       f.avg_supplycost,
       f.total_discounted_sales,
       (SELECT COUNT(DISTINCT o.o_orderkey)
        FROM orders o
        JOIN lineitem li ON o.o_orderkey = li.l_orderkey
        WHERE li.l_partkey = f.p_partkey AND o.o_orderstatus = 'O') AS total_orders
FROM FinalStats f
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE f.total_discounted_sales > 1000
AND (f.avg_account_balance IS NOT NULL OR f.avg_supplycost IS NOT NULL)
ORDER BY f.total_discounted_sales DESC
LIMIT 10;
