
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE sh.level < 3 AND s.s_acctbal < sh.s_acctbal
),
customer_summary AS (
    SELECT c.c_nationkey, COUNT(DISTINCT c.c_custkey) AS cust_count,
           SUM(COALESCE(c.c_acctbal, 0)) AS total_balance
    FROM customer c
    GROUP BY c.c_nationkey
),
detailed_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
),
nation_region AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT ns.n_name, rg.r_name, cs.cust_count, cs.total_balance,
       COALESCE(SUM(d.order_total), 0) AS total_order_value,
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count
FROM customer_summary cs
JOIN nation ns ON cs.c_nationkey = ns.n_nationkey
LEFT JOIN nation_region rg ON rg.n_nationkey = ns.n_nationkey
LEFT JOIN detailed_orders d ON d.o_orderkey IN (SELECT o.o_orderkey 
                                                  FROM orders o 
                                                  JOIN customer c ON o.o_custkey = c.c_custkey 
                                                  WHERE c.c_nationkey = ns.n_nationkey)
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = ns.n_nationkey
WHERE cs.cust_count > 10 AND (cs.total_balance IS NOT NULL OR cs.total_balance > 1000)
GROUP BY ns.n_name, rg.r_name, cs.cust_count, cs.total_balance
HAVING COUNT(DISTINCT sh.s_suppkey) > 5
ORDER BY total_order_value DESC, ns.n_name DESC
LIMIT 10;
