WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey = (SELECT MIN(n_nationkey) FROM nation)

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_regionkey
    WHERE n.n_nationkey <> nh.n_nationkey
),
high_value_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice)
        FROM part p2
    )
),
supplier_part AS (
    SELECT ps.ps_partkey, s.s_name, ps.ps_supplycost, ps.ps_availqty
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty < (
        SELECT AVG(ps2.ps_availqty)
        FROM partsupp ps2
    )
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    nh.n_name AS nation_name,
    p.p_name AS part_name,
    sp.s_name AS supplier_name,
    co.total_value AS order_total,
    DENSE_RANK() OVER (PARTITION BY nh.n_name ORDER BY co.total_value DESC) as sales_rank,
    CASE 
        WHEN co.total_value IS NULL THEN 'No Sales'
        ELSE 'Sales Present' 
    END AS sales_status
FROM region r
LEFT JOIN nation_hierarchy nh ON r.r_regionkey = nh.n_regionkey
JOIN high_value_parts p ON p.p_partkey = (
        SELECT ps.ps_partkey 
        FROM supplier_part ps
        WHERE ps.ps_supplycost = (
            SELECT MAX(ps2.ps_supplycost)
            FROM supplier_part ps2
            WHERE ps2.ps_partkey = p.p_partkey
        )
        ORDER BY ps.ps_availqty DESC
        LIMIT 1
    )
LEFT JOIN supplier_part sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN customer_orders co ON co.o_orderkey = (
        SELECT MIN(o_orderkey) 
        FROM orders 
        WHERE o_custkey = co.c_custkey
    )
WHERE r.r_name IS NOT NULL
ORDER BY nh.n_name, order_total DESC, sales_rank;
