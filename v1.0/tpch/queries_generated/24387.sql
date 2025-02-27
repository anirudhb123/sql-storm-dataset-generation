WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, c_nationkey, 1 AS level
    FROM customer
    WHERE c_acctbal > (
        SELECT AVG(c_acctbal) FROM customer
    )
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 4
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_orderstatus,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' AND o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT ch.c_name, ch.c_acctbal, si.s_name, si.s_acctbal, od.total_revenue
FROM CustomerHierarchy ch
FULL OUTER JOIN SupplierInfo si ON ch.c_nationkey = si.s_suppkey
FULL OUTER JOIN OrderDetails od ON ch.c_custkey = od.o_orderkey
WHERE (ch.c_acctbal IS NOT NULL OR si.s_acctbal IS NOT NULL)
  AND (od.total_revenue >= 10000 OR od.total_revenue IS NULL)
ORDER BY ch.c_acctbal DESC NULLS LAST, si.s_acctbal ASC NULLS FIRST;
