WITH RECURSIVE NATION_HIERARCHY AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NATION_HIERARCHY nh ON n.n_regionkey = nh.n_nationkey
),
SUPPLIER_STATISTICS AS (
    SELECT s.s_nationkey,
           COUNT(DISTINCT s.s_suppkey) AS num_suppliers,
           SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    GROUP BY s.s_nationkey
),
ORDER_SUMMARY AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT r.r_name,
       nh.n_name,
       COALESCE(ss.num_suppliers, 0) AS num_suppliers,
       COALESCE(ss.total_acctbal, 0) AS total_supplier_balance,
       os.total_spent,
       os.order_count,
       os.avg_order_value,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY os.total_spent DESC) AS rank
FROM region r
LEFT JOIN NATION_HIERARCHY nh ON r.r_regionkey = nh.n_regionkey
LEFT JOIN SUPPLIER_STATISTICS ss ON nh.n_nationkey = ss.s_nationkey
LEFT JOIN ORDER_SUMMARY os ON nh.n_nationkey = os.c_custkey
WHERE (os.total_spent IS NOT NULL OR ss.num_suppliers IS NOT NULL)
  AND r.r_name IS NOT NULL
  AND (ss.total_acctbal > 10000 OR os.order_count > 5)
ORDER BY r.r_name, rank;
