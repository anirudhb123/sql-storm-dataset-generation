WITH RECURSIVE customer_hierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal,
           CAST(c_name AS VARCHAR(255)) AS full_path, 1 AS level
    FROM customer
    WHERE c_acctbal IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal,
           CONCAT(ch.full_path, ' > ', c.c_name), ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_nationkey = c.c_nationkey AND ch.custkey <> c.c_custkey
    WHERE ch.level < 5
),
filtered_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
           SUM(ps.ps_supplycost) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    HAVING SUM(ps.ps_supplycost) > 1000.00
),
latest_order_dates AS (
    SELECT o.o_custkey, MAX(o.o_orderdate) AS last_order_date
    FROM orders o
    GROUP BY o.o_custkey
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_account_balance,
           STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name, cs.custkey, 
       COALESCE(ch.full_path, 'No Hierarchy') AS hierarchy,
       COALESCE(fs.total_supply_cost, 0) AS total_supply_cost,
       COALESCE(ls.last_order_date, 'No Orders') AS last_order
FROM nation_summary n
LEFT JOIN customer_hierarchy ch ON ch.c_nationkey = n.n_nationkey
LEFT JOIN filtered_suppliers fs ON fs.s_nationkey = n.n_nationkey
LEFT JOIN latest_order_dates ls ON ls.o_custkey = ch.c_custkey
WHERE (n.supplier_count IS NULL OR n.supplier_count > 0)
  AND (ch.level BETWEEN 1 AND 3 OR ch.level IS NULL)
ORDER BY n.n_name, fs.total_supply_cost DESC, ch.full_path;
