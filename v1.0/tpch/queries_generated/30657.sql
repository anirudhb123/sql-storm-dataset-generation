WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_account_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
part_sales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY p.p_partkey, p.p_name
)
SELECT ns.n_name AS nation_name, ps.p_name AS part_name, ps.total_sales, sh.level,
       ns.supplier_count, ns.total_account_balance
FROM nation_summary ns
LEFT JOIN part_sales ps ON ns.n_nationkey = ps.p_partkey
LEFT JOIN supplier_hierarchy sh ON ns.supplier_count > sh.level
WHERE (ps.total_sales IS NULL OR ps.total_sales > 50000)
  AND (sh.level IS NULL OR sh.level < 3)
ORDER BY ns.total_account_balance DESC, ps.total_sales DESC
LIMIT 100;
