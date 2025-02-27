WITH supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
    )
), part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
), order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, l.l_quantity, l.l_extendedprice
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
) 
SELECT si.nation_name, ps.p_name, SUM(os.l_extendedprice * (1 - os.l_discount)) AS total_revenue
FROM supplier_info si
JOIN part_supplier ps ON si.s_suppkey = ps.ps_suppkey
JOIN order_summary os ON ps.ps_partkey = os.o_orderkey
WHERE si.s_acctbal > 1000
GROUP BY si.nation_name, ps.p_name
ORDER BY total_revenue DESC
LIMIT 10;
