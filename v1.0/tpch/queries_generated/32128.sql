WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), 

PartLineItems AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS line_items_count
    FROM lineitem l
    WHERE l.l_shipdate >= '2021-01-01' AND l.l_shipdate <= '2021-12-31'
    GROUP BY l.l_orderkey
),

CustomerSummary AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
)

SELECT r.r_name,
       SUM(pl.total_revenue) AS revenue,
       AVG(cs.total_spent) AS avg_customer_spent,
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       MAX(sh.level) AS max_supplier_level
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
JOIN PartLineItems pl ON s.s_suppkey = pl.l_orderkey
LEFT JOIN CustomerSummary cs ON cs.c_custkey = s.s_nationkey 
WHERE r.r_name ILIKE '%east%'
GROUP BY r.r_name
HAVING SUM(pl.total_revenue) > 100000
ORDER BY revenue DESC
LIMIT 10;
