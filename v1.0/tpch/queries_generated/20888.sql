WITH RECURSIVE supplier_revenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '2021-01-01'
    GROUP BY s.s_suppkey, s.s_name
),
ranked_suppliers AS (
    SELECT 
        sr.s_suppkey,
        sr.s_name,
        sr.total_revenue,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS rnk
    FROM supplier_revenue sr
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS highest_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
high_value_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count,
        co.highest_order_value
    FROM customer c
    JOIN customer_orders co ON c.c_custkey = co.c_custkey
    WHERE co.highest_order_value > 1000
),
supply_chain AS (
    SELECT 
        ns.n_nationkey,
        ns.n_name,
        COALESCE(SUM(sr.total_revenue), 0) AS total_revenue,
        COUNT(DISTINCT hs.c_custkey) AS customer_count
    FROM nation ns
    LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
    LEFT JOIN supplier_revenue sr ON s.s_suppkey = sr.s_suppkey
    LEFT JOIN high_value_customers hs ON hs.c_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
        WHERE o.o_orderstatus = 'F'
    )
    GROUP BY ns.n_nationkey, ns.n_name
)
SELECT 
    sc.n_nationkey,
    sc.n_name,
    CASE 
        WHEN sc.customer_count IS NULL THEN 'No Customers'
        ELSE CONCAT(sc.customer_count, ' Customers')
    END AS customer_count,
    CASE 
        WHEN sc.total_revenue IS NULL OR sc.total_revenue = 0 THEN 'No Revenue'
        ELSE FORMAT(sc.total_revenue, 2, 'en_US')
    END AS total_revenue
FROM supply_chain sc
WHERE sc.total_revenue > (
    SELECT AVG(total_revenue) 
    FROM ranked_suppliers
    WHERE rnk <= 10
) OR sc.customer_count > (SELECT AVG(order_count) FROM customer_orders)
ORDER BY sc.n_nationkey;
