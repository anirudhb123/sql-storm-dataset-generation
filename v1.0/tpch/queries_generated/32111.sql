WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier
        WHERE s_acctbal IS NOT NULL
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
total_order_value AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate <= CURRENT_DATE
    GROUP BY o.o_orderkey
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice > 10000
),
supplier_part_availability AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
ranked_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
)
SELECT 
    r.r_name,
    nt.ranked_part_name,
    nt.total_order_value,
    nh.total_avail_qty,
    s.s_name AS supplier_name,
    s.s_acctbal AS supplier_balance
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN (
    SELECT p.p_partkey, p.p_name AS ranked_part_name, 
           pv.p_retailprice, 
           p_part_av.total_available, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY p.p_retailprice DESC) AS ranked_part
    FROM ranked_parts p
    JOIN supplier_part_availability p_part_av ON p.p_partkey = p_part_av.ps_partkey
    WHERE p.price_rank <= 5
) nt ON n.n_nationkey = nt.ranked_part
LEFT JOIN total_order_value t ON nt.ranked_part = t.o_orderkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN (
    SELECT SUM(ps.ps_availqty) AS total_avail_qty, ps.ps_partkey
    FROM partsupp ps
    GROUP BY ps.ps_partkey
) nh ON nt.p_partkey = nh.ps_partkey
WHERE s.s_acctbal IS NOT NULL
ORDER BY r.r_name, nt.total_order_value DESC;
