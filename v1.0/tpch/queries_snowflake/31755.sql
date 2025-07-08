WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > 10000
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
           COUNT(l.l_linenumber) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerSummaries AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_amount
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationRegion AS (
    SELECT n.n_name, r.r_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT c.c_name, cs.total_spent, cs.avg_order_amount,
       sh.s_name AS top_supplier, sh.level AS supplier_level, 
       nr.n_name, nr.supplier_count
FROM CustomerSummaries cs
JOIN customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN SupplierHierarchy sh ON sh.s_acctbal = (SELECT MAX(s2.s_acctbal) 
                                                    FROM supplier s2 
                                                    WHERE s2.s_acctbal < cs.avg_order_amount)
JOIN NationRegion nr ON c.c_nationkey = (SELECT n.n_nationkey 
                                          FROM nation n 
                                          WHERE n.n_name = 'USA')
WHERE cs.total_spent IS NOT NULL
ORDER BY cs.total_spent DESC
LIMIT 10;
