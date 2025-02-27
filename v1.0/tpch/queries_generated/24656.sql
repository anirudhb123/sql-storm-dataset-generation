WITH RECURSIVE customer_hierarchy AS (
    SELECT c_custkey,
           c_name,
           c_acctbal,
           c_nationkey,
           CAST(c_name AS VARCHAR(100)) AS full_name,
           0 AS level
    FROM customer
    WHERE c_acctbal IS NOT NULL AND c_acctbal > (
        SELECT AVG(c_acctbal)
        FROM customer
        WHERE c_nationkey IS NOT NULL
    )
    UNION ALL
    SELECT c.c_custkey,
           c.c_name,
           c.c_acctbal,
           c.c_nationkey,
           CONCAT(ch.full_name, ' -> ', c.c_name) AS full_name,
           ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_custkey = ch.c_nationkey
    WHERE ch.level < 5 AND c.c_acctbal IS NOT NULL
),
region_summary AS (
    SELECT r.r_regionkey,
           r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_supplier_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT r.r_name,
       COALESCE(c.cust_with_high_bal, 'None') AS cust_with_high_bal,
       rs.nation_count,
       rs.total_supplier_acctbal,
       CASE
           WHEN rs.total_supplier_acctbal IS NULL THEN 'No Supplier'
           ELSE 'Supplier Exists'
       END AS supplier_status,
       SUM(CASE WHEN l.l_discount > 0.2 THEN l.l_extendedprice * (1 - l.l_discount) END) AS total_discounted_sales
FROM region_summary rs
JOIN lineitem l ON l.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    JOIN customer_hierarchy ch ON o.o_custkey = ch.c_custkey
)
LEFT JOIN (
    SELECT c.c_custkey, MAX(c.c_acctbal) AS cust_with_high_bal
    FROM customer c
    GROUP BY c.c_custkey
) c ON c.c_custkey = (SELECT c_h.c_custkey FROM customer_hierarchy c_h ORDER BY c_h.c_acctbal DESC LIMIT 1)
GROUP BY r.r_name, c.cust_with_high_bal, rs.nation_count, rs.total_supplier_acctbal
HAVING SUM(COALESCE(l.l_quantity, 0)) > 1000
ORDER BY rs.total_supplier_acctbal DESC, r.r_name;
