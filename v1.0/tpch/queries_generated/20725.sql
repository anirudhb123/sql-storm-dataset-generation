WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
aggregated_data AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
filtered_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_mktsegment
    FROM customer c
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_acctbal IS NOT NULL)
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, MAX(o.o_totalprice) AS max_total_price
    FROM orders o
    GROUP BY o.o_orderkey, o.o_custkey
),
final_selection AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        ad.total_supply_cost, 
        fc.c_name, 
        fc.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY fc.c_mktsegment ORDER BY ad.total_supply_cost DESC) AS rn
    FROM aggregated_data ad
    JOIN filtered_customers fc ON fc.c_custkey IN (SELECT o.o_custkey FROM order_summary o WHERE o.max_total_price > 1000)
    WHERE ad.total_supply_cost IS NOT NULL AND LENGTH(fc.c_name) > 3
),
outer_joined_summary AS (
    SELECT f.*, r.r_name
    FROM final_selection f
    LEFT JOIN nation n ON n.n_nationkey = (SELECT n_nationkey FROM supplier s WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = f.p_partkey) LIMIT 1)
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    os.p_partkey, 
    os.p_name, 
    os.total_supply_cost, 
    os.c_name, 
    os.c_acctbal, 
    os.r_name,
    CASE 
        WHEN os.total_supply_cost IS NULL THEN 'Cost Unknown'
        ELSE 'Cost Known'
    END AS cost_info,
    COALESCE(NULLIF(os.c_acctbal, 0), 0) AS adjusted_account_balance
FROM outer_joined_summary os
WHERE os.r_name IN ('ASIA', 'EUROPE')
    AND os.r_name IS NOT NULL
ORDER BY os.total_supply_cost DESC, os.c_name ASC
LIMIT 100;
