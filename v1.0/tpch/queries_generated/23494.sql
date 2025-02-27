WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) AND sh.level < 3
),
customer_orders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT *
    FROM customer_orders
    WHERE total_spent >= (SELECT AVG(total_spent) FROM customer_orders)
),
part_supplier AS (
    SELECT
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
filtered_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.total_supply_cost
    FROM part_supplier p
    WHERE supplier_count > 5 AND total_supply_cost > 10000.00
),
final_selection AS (
    SELECT 
        cv.c_custkey,
        cv.c_name,
        COALESCE(sp.s_name, 'Unknown Supplier') AS supplier_name,
        pp.p_partkey,
        pp.p_name,
        ROW_NUMBER() OVER (PARTITION BY cv.c_custkey ORDER BY pp.total_supply_cost DESC) AS rn
    FROM high_value_customers cv
    LEFT JOIN supplier_hierarchy sp ON cv.c_custkey = sp.s_suppkey
    CROSS JOIN filtered_parts pp
)
SELECT
    f.c_custkey,
    f.c_name,
    f.supplier_name,
    f.p_partkey,
    f.p_name
FROM final_selection f
WHERE f.rn = 1
  AND (f.supplier_name IS NOT NULL OR f.supplier_name IS NOT NULL)
ORDER BY f.c_custkey, f.p_partkey;
