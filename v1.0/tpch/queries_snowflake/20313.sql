
WITH supplier_parts AS (
    SELECT s.s_suppkey, p.p_partkey, p.p_name, s.s_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 0
    UNION ALL
    SELECT sp.s_suppkey, sp.p_partkey, sp.p_name, sp.s_acctbal
    FROM supplier_parts sp
    JOIN partsupp ps ON sp.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE (SELECT COUNT(*) FROM supplier_parts sp2 WHERE sp2.s_suppkey = sp.s_suppkey) < 5
), 
filtered_supplier AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_name NOT LIKE '%Inc%' 
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost) > 1000
), 
ranked_orders AS (
    SELECT o.o_orderkey, c.c_name, o.o_totalprice,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice IS NOT NULL
)
SELECT DISTINCT sp.s_suppkey, sp.p_partkey, sp.p_name, fs.total_cost, ro.c_name, ro.o_totalprice
FROM supplier_parts sp
LEFT JOIN filtered_supplier fs ON sp.s_suppkey = fs.s_suppkey
FULL OUTER JOIN ranked_orders ro ON fs.s_suppkey = ro.o_orderkey
WHERE ro.order_rank <= 10 
  AND (sp.p_name IS NULL OR sp.p_name NOT LIKE '%XYZ%')
  AND sp.s_acctbal = (SELECT MAX(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
ORDER BY fs.total_cost DESC, ro.o_totalprice ASC NULLS LAST;
