WITH RECURSIVE order_hierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        1 AS depth
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' 
    AND o.o_orderdate >= '2023-01-01'
    
    UNION ALL

    SELECT 
        oh.o_orderkey,
        oh.o_orderdate,
        oh.o_totalprice,
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        depth + 1
    FROM orders oh
    JOIN order_hierarchy ohH ON oh.o_custkey = ohH.c_custkey
    JOIN customer c ON oh.o_custkey = c.c_custkey
    WHERE oh.o_orderstatus = 'O' 
    AND oh.o_orderdate >= '2023-01-01'
    AND depth < 5
),
part_supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
product_summary AS (
    SELECT 
        ps.p_partkey,
        ps.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM part_supplier ps
    GROUP BY ps.p_partkey, ps.p_name
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.total_spent,
    co.order_count,
    ps.p_name,
    ps.total_available,
    ps.avg_cost,
    COALESCE(oh.depth, 0) AS order_depth
FROM customer_order_summary co
LEFT JOIN product_summary ps ON co.total_spent > ps.avg_cost
LEFT JOIN order_hierarchy oh ON co.c_custkey = oh.c_custkey
WHERE co.customer_rank <= 10
ORDER BY co.total_spent DESC, ps.total_available DESC;
