WITH RECURSIVE supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    HAVING SUM(ps.ps_availqty * ps.ps_supplycost) > 1000000
),
ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_total,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
nation_supplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    ps.p_partkey,
    p.p_name,
    n.n_name,
    ss.total_supply_value,
    no.o_orderkey,
    no.net_total,
    ns.supplier_count,
    ns.avg_supplier_balance
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier_summary ss ON ps.ps_suppkey = ss.s_suppkey
JOIN ranked_orders no ON no.o_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey = ss.s_nationkey
) 
LEFT JOIN nation_supplier ns ON ns.n_name = (
    SELECT n.n_name 
    FROM nation n 
    WHERE n.n_nationkey = ss.s_nationkey
)
WHERE ss.total_supply_value IS NOT NULL 
AND no.order_rank = 1
ORDER BY ss.total_supply_value DESC, no.net_total DESC;
