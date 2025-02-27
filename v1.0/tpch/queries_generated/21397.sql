WITH RECURSIVE price_tracking AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2) 
    GROUP BY c.c_custkey, c.c_name
),
ranked_nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        RANK() OVER (ORDER BY COUNT(s.s_suppkey) DESC) AS nation_rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    rc.c_custkey,
    rc.c_name,
    rn.n_name AS top_nation,
    pt.p_name,
    pt.total_supply_cost,
    COALESCE(sl.special_discount, 0) AS decent_discount,
    ROW_NUMBER() OVER (PARTITION BY rc.c_custkey ORDER BY pt.total_supply_cost DESC) AS supplier_rank
FROM customer_orders rc
JOIN ranked_nations rn ON rc.order_count > 5 AND rn.nation_rank <= 3
LEFT JOIN price_tracking pt ON rc.order_count > 0 AND pt.total_supply_cost > 1000
LEFT JOIN (
    SELECT 
        c.c_custkey,
        AVG(l.l_discount) AS special_discount
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'R' AND l.l_discount IS NOT NULL
    GROUP BY c.c_custkey
) sl ON sl.c_custkey = rc.c_custkey
WHERE (pt.total_supply_cost IS NOT NULL OR rc.total_spent > 500) 
AND (rn.n_name IS NOT NULL OR rc.order_count IS NULL)
ORDER BY rc.total_spent DESC, pt.total_supply_cost ASC;
