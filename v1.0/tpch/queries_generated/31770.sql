WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, 1 AS level
    FROM part
    WHERE p_size <= 20
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice, ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_size > ph.p_size AND ph.level < 5
),
CustomerRanked AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT s.s_nationkey, AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
NationPerformance AS (
    SELECT n.n_nationkey, n.n_name, COALESCE(cs.total_spent, 0) AS total_spent,
           COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost
    FROM nation n
    LEFT JOIN CustomerRanked cs ON n.n_nationkey = cs.c_custkey
    LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
)
SELECT np.n_name,
       CASE WHEN np.total_spent > 100000 THEN 'High'
            WHEN np.total_spent BETWEEN 50000 AND 100000 THEN 'Medium'
            ELSE 'Low' END AS spending_category,
       np.avg_supply_cost,
       (SELECT COUNT(*)
        FROM PartHierarchy ph
        WHERE ph.p_retailprice > np.avg_supply_cost) AS parts_above_avg_price
FROM NationPerformance np
ORDER BY np.n_name ASC;
