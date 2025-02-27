WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment,
           0 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment,
           sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, s.s_suppkey, ps.ps_availqty,
           COALESCE(ps.ps_supplycost, 0) AS supply_cost,
           CASE 
               WHEN ps.ps_availqty IS NULL THEN 'Not Available'
               ELSE 'Available'
           END AS availability
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT
    ns.n_name AS nation_name,
    COUNT(DISTINCT ps.p_partkey) AS part_count,
    SUM(ps.supply_cost) AS total_supply_cost,
    MAX(sh.hierarchy_level) AS max_supplier_hierarchy,
    AVG(tc.total_spent) AS avg_top_customer_spent
FROM NationStats ns
LEFT JOIN PartSupplier ps ON ps.s_suppkey IN (
        SELECT DISTINCT s_suppkey
        FROM SupplierHierarchy sh
        WHERE sh.hierarchy_level = (
            SELECT MAX(hierarchy_level) FROM SupplierHierarchy
        )
    )
JOIN TopCustomers tc ON tc.total_spent > 1500
GROUP BY ns.n_name
HAVING SUM(ps.supply_cost) IS NOT NULL
   OR SUM(ps.supply_cost) > 5000
ORDER BY total_supply_cost DESC NULLS LAST;
