WITH RECURSIVE customer_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    JOIN customer_orders co ON co.o_custkey = o.o_custkey
    WHERE o.o_orderdate > co.o_orderdate
),
supplier_profit AS (
    SELECT ps.ps_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_profit
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    WHERE l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2023-12-31'
    GROUP BY ps.ps_suppkey
),
top_nations AS (
    SELECT n.n_name, SUM(s.s_acctbal) AS total_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
    HAVING SUM(s.s_acctbal) > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)
SELECT 
    c.c_name,
    COALESCE(co.o_orderkey, -1) AS related_order,
    s.s_name,
    CASE 
        WHEN tp.total_balance IS NULL THEN 'Unknown balance'
        ELSE CONCAT('Balance: ', CAST(tp.total_balance AS VARCHAR))
    END AS nation_balance_info,
    ROW_NUMBER() OVER (PARTITION BY c.custkey ORDER BY co.o_orderdate DESC) AS order_sequence,
    COUNT(*) FILTER (WHERE l.l_returnflag = 'R') AS returned_items_count,
    MAX(l.l_tax) OVER (PARTITION BY s.s_suppkey) AS highest_tax_rate
FROM customer c
LEFT JOIN customer_orders co ON c.c_custkey = co.o_custkey
LEFT JOIN supplier s ON s.s_nationkey = c.c_nationkey
LEFT JOIN supplier_profit sp ON s.s_suppkey = sp.ps_suppkey
LEFT JOIN top_nations tp ON tp.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = s.s_nationkey)
LEFT JOIN lineitem l ON l.l_orderkey = co.o_orderkey
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
GROUP BY c.c_name, co.o_orderkey, s.s_name, tp.total_balance
ORDER BY co.o_orderdate DESC NULLS LAST, total_balance DESC
LIMIT 100;
