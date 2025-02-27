WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_nationkey IN (SELECT DISTINCT s_nationkey FROM supplier WHERE s_acctbal IS NOT NULL)

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_regionkey
    WHERE nh.level < 5
), ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY ns.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation_hierarchy ns ON s.s_nationkey = ns.n_nationkey
), high_value_parts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp)
), expense_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_expense,
           RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS expense_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), final_report AS (
    SELECT p.p_name, p.p_partkey, ns.n_name AS supplier_nation, ns.level AS nation_level,
           COALESCE(rh.total_supply_cost, 0) AS supply_cost, 
           es.total_expense,
           CASE
               WHEN es.total_expense IS NULL THEN 'NO EXPENSE'
               WHEN es.expense_rank < 5 THEN 'HIGH SPENDER'
               ELSE 'LOW SPENDER'
           END AS spending_category
    FROM part p
    LEFT JOIN high_value_parts rh ON p.p_partkey = rh.ps_partkey
    LEFT JOIN ranked_suppliers rs ON rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
    LEFT JOIN nation_hierarchy ns ON rs.s_nationkey = ns.n_nationkey
    LEFT JOIN expense_summary es ON es.o_orderkey = (SELECT MAX(o_orderkey) FROM orders WHERE o_orderkey < 10)  -- obscure subquery
    WHERE p.p_size BETWEEN 1 AND 10 OR p.p_retailprice IS NULL  -- complicated predicate
)
SELECT *
FROM final_report
WHERE (spending_category = 'HIGH SPENDER' OR supply_cost > 1000)
AND (total_expense IS NOT NULL OR total_expense IS NULL)  -- NULL logic
ORDER BY supplier_nation, nation_level DESC;
