WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2021-01-01' AND o.o_orderdate < DATE '2022-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
top_sales AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_sales
    FROM ranked_orders ro
    WHERE ro.order_rank <= 10
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.total_sales,
    c.c_name,
    n.n_name AS customer_nation,
    s.s_name AS supplier_name,
    SUM(ps.ps_supplycost) AS total_supplier_cost
FROM top_sales t
JOIN orders o ON t.o_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier s ON EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey = t.o_orderkey
        ) 
        AND ps.ps_suppkey = s.s_suppkey
    )
JOIN nation n ON c.c_nationkey = n.n_nationkey
GROUP BY t.o_orderkey, t.o_orderdate, c.c_name, n.n_name, s.s_name
ORDER BY t.total_sales DESC;
