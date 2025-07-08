WITH RECURSIVE supplier_parts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 10
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, p2.p_partkey, p2.p_name, ps2.ps_availqty, ps2.ps_supplycost
    FROM supplier_parts sp
    JOIN partsupp ps2 ON sp.p_partkey = ps2.ps_partkey
    JOIN supplier s2 ON ps2.ps_suppkey = s2.s_suppkey
    JOIN part p2 ON ps2.ps_partkey = p2.p_partkey
    WHERE p2.p_size < 5 AND sp.p_partkey IS NOT NULL
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) as total_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
order_summary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) as total_price,
           COUNT(DISTINCT o.o_orderkey) as order_count,
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) as price_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT ns.n_name, ns.total_balance, 
       CASE WHEN os.order_count > 5 THEN 'High Value' ELSE 'Low Value' END AS customer_value,
       sp.s_name, sp.p_name, sp.ps_availqty, sp.ps_supplycost 
FROM nation_summary ns
LEFT JOIN order_summary os ON ns.n_nationkey = os.c_custkey
LEFT JOIN supplier_parts sp ON sp.s_suppkey = ns.n_nationkey
WHERE (ns.total_balance IS NOT NULL OR sp.ps_supplycost < 50.00)
ORDER BY ns.n_name, customer_value DESC, sp.ps_availqty ASC
FETCH FIRST 100 ROWS ONLY;
