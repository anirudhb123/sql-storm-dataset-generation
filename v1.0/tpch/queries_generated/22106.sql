WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.level < 5
),
PartStats AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerSummary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS row_num
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
AggregateLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(DISTINCT l.l_partkey) AS lineitem_count
    FROM lineitem l
    WHERE l.l_shipdate > '1995-12-31' 
    GROUP BY l.l_orderkey
)
SELECT DISTINCT
    n.n_name AS nation_name,
    p.p_name AS part_name,
    ps.supply_cost_provided, 
    COALESCE(SUM(ls.total_price), 0) AS total_line_items_value,
    CASE 
        WHEN AVG(COALESCE(c.total_spent, 0)) IS NULL THEN 'NO_CUSTOMERS'
        ELSE AVG(c.total_spent)
    END AS avg_customer_spending,
    CASE 
        WHEN sh.level = 0 THEN 'Base Supplier'
        ELSE 'Supplier Level ' || sh.level
    END AS supplier_level,
    CASE 
        WHEN p.p_size IS NOT NULL AND p.p_size % 2 = 0 
        THEN 'Even Size Part'
        ELSE 'Odd Size Part'
    END AS part_size_category
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN nation n ON sh.s_nationkey = n.n_nationkey
LEFT JOIN AggregateLineItems ls ON ls.l_orderkey = ps.ps_partkey
LEFT JOIN CustomerSummary c ON c.c_custkey = ls.l_orderkey
WHERE
    (sh.s_acctbal IS NOT NULL AND sh.s_acctbal > 500)
    OR (p.p_retailprice IS NULL)
GROUP BY
    n.n_name,
    p.p_name,
    ps.ps_supplycost,
    sh.level
HAVING AVG(COALESCE(c.total_spent, 0)) BETWEEN 100 AND 1000
   AND COUNT(DISTINCT ps.ps_suppkey) > 1
ORDER BY 1, 2, 3 DESC, part_size_category
LIMIT 50;
