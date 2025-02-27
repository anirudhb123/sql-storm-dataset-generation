WITH RECURSIVE top_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_order
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
final_summary AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        os.total_revenue,
        ts.total_cost AS supplier_cost
    FROM customer_orders co
    LEFT JOIN order_summary os ON os.total_revenue > 5000
    LEFT JOIN top_suppliers ts ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey))
)
SELECT 
    f.c_custkey,
    f.c_name,
    f.total_spent,
    COALESCE(f.total_revenue, 0) AS total_revenue,
    COALESCE(f.supplier_cost, 0) AS supplier_cost,
    CASE 
        WHEN f.total_spent IS NULL THEN 'No Orders'
        WHEN f.total_spent > f.supplier_cost THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status
FROM final_summary f
WHERE f.total_spent IS NOT NULL
ORDER BY f.total_spent DESC, f.c_custkey;
