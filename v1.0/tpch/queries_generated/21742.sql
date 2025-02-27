WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_brand, p_container, 
           REPLACE(p_comment, ' ', '-') AS modified_comment,
           1 AS level
    FROM part
    WHERE p_size > 10

    UNION ALL

    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_container, 
           CONCAT(ph.modified_comment, '|', REPLACE(p.p_comment, ' ', '-')) AS modified_comment,
           ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON ph.p_partkey = p.p_partkey
),
TotalCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerStats AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FilteredNation AS (
    SELECT n.n_nationkey, n.n_name 
    FROM nation n
    WHERE EXISTS (
        SELECT 1 
        FROM supplier s 
        WHERE s.s_nationkey = n.n_nationkey AND s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey = n.n_nationkey
        )
    )
)
SELECT ph.p_partkey, ph.p_name, ph.modified_comment, 
       tc.total_supply_cost, cs.order_count, cs.total_spent, fn.n_name
FROM PartHierarchy ph
LEFT JOIN TotalCost tc ON ph.p_partkey = tc.ps_partkey
FULL OUTER JOIN CustomerStats cs ON cs.order_count IS NOT NULL AND cs.customer_rank <= 10
LEFT JOIN FilteredNation fn ON fn.n_nationkey = (
    SELECT n.n_regionkey 
    FROM nation n 
    WHERE n.n_nationkey = (SELECT MAX(nationkey) FROM nation)
)
WHERE ph.level BETWEEN 1 AND 5
  AND (tc.total_supply_cost IS NULL OR tc.total_supply_cost > 2000)
ORDER BY cs.total_spent DESC NULLS LAST, ph.p_partkey ASC
LIMIT 50 OFFSET 10;
