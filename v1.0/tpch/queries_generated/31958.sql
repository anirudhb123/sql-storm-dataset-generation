WITH RECURSIVE date_series AS (
    SELECT MIN(o_orderdate) AS order_date
    FROM orders
    UNION ALL
    SELECT DATE_ADD(order_date, INTERVAL 1 DAY)
    FROM date_series
    WHERE order_date < (SELECT MAX(o_orderdate) FROM orders)
),
customer_summary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
nation_supplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
),
recent_orders AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY l.l_orderkey, l.l_partkey
)
SELECT 
    ds.order_date,
    cs.c_name,
    cs.total_orders,
    COALESCE(ns.total_suppliers, 0) AS total_suppliers,
    COALESCE(ns.total_supply_cost, 0.00) AS total_supply_cost,
    COALESCE(ro.revenue, 0.00) AS recent_revenue,
    CASE 
        WHEN cs.rank_within_nation = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM date_series ds
LEFT JOIN customer_summary cs ON cs.total_orders > 0
LEFT JOIN nation_supplier ns ON TRUE
LEFT JOIN recent_orders ro ON ro.l_orderkey = cs.total_orders
WHERE cs.c_acctbal IS NOT NULL AND cs.total_spent > 1000
ORDER BY ds.order_date, cs.c_name;
