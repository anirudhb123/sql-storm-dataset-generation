WITH supplier_performance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    GROUP BY s.s_suppkey, s.s_name
),
customer_analysis AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT 
        ca.c_custkey,
        ca.c_name,
        ca.total_spent,
        CASE 
            WHEN ca.total_spent > 10000 THEN 'VIP'
            ELSE 'Regular'
        END AS customer_type
    FROM customer_analysis ca
    WHERE ca.order_count > 5
),
nation_performance AS (
    SELECT 
        n.n_name,
        MAX(sp.total_cost) AS max_supplier_cost,
        SUM(sp.total_cost) AS total_supplier_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN supplier_performance sp ON s.s_suppkey = sp.s_suppkey
    GROUP BY n.n_name
)
SELECT 
    ca.c_name,
    ca.order_count,
    hvc.customer_type,
    np.n_name,
    np.total_supplier_cost,
    np.max_supplier_cost,
    COALESCE(sp.total_cost, 0) AS supplier_cost
FROM high_value_customers hvc
JOIN customer_analysis ca ON hvc.c_custkey = ca.c_custkey
LEFT JOIN nation_performance np ON np.n_name = (
    SELECT n.n_name 
    FROM nation n 
    WHERE n.n_nationkey = (
        SELECT s.n_nationkey
        FROM supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        WHERE ps.ps_partkey = (
            SELECT l.l_partkey
            FROM lineitem l
            WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ca.c_custkey)
            LIMIT 1
        )
        LIMIT 1
    )
)
LEFT JOIN supplier_performance sp ON sp.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps
    WHERE ps.ps_availqty = (
        SELECT MAX(ps_availqty)
        FROM partsupp
        WHERE ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ca.c_custkey)
        )
    )
)
WHERE hvc.total_spent IS NOT NULL
ORDER BY ca.total_spent DESC, hvc.c_name ASC;
