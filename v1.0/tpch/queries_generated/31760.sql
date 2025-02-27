WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND s.s_suppkey != sh.s_suppkey
),

TotalOrderValue AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),

NationSupplier AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),

FinalReport AS (
    SELECT ns.n_name, ns.supplier_count, ns.avg_acctbal,
           COALESCE(SUM(tv.total_value), 0) AS total_order_value,
           COUNT(DISTINCT sh.s_suppkey) AS associated_suppliers 
    FROM NationSupplier ns
    LEFT JOIN TotalOrderValue tv ON ns.n_nationkey = (
        SELECT c.c_nationkey
        FROM customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
        WHERE o.o_orderkey IN (
            SELECT l.l_orderkey
            FROM lineitem l
            GROUP BY l.l_orderkey
            HAVING SUM(l.l_quantity) > 50
        )
        LIMIT 1
    )
    LEFT JOIN SupplierHierarchy sh ON ns.n_nationkey = sh.s_nationkey
    GROUP BY ns.n_name, ns.supplier_count, ns.avg_acctbal
)

SELECT fr.n_name, 
       fr.supplier_count, 
       fr.avg_acctbal, 
       fr.total_order_value, 
       fr.associated_suppliers
FROM FinalReport fr
WHERE fr.supplier_count > 5 AND fr.total_order_value > 100000
ORDER BY fr.total_order_value DESC, fr.avg_acctbal ASC;
