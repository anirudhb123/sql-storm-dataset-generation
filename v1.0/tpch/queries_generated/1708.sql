WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS average_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM 
        customer_orders
    WHERE 
        total_spent > 5000
)
SELECT 
    nv.n_name AS nation_name,
    COUNT(DISTINCT h.c_custkey) AS high_value_customer_count,
    COALESCE(SUM(s.total_supply_cost), 0) AS total_supply_cost_from_high_value_customers,
    AVG(h.average_order_value) AS average_order_value_from_high_value_customers
FROM 
    high_value_customers h
JOIN 
    nation nv ON h.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nv.n_nationkey)
LEFT JOIN 
    supplier_summary s ON s.rank = 1
WHERE 
    h.spending_rank <= 10
GROUP BY 
    nv.n_name
ORDER BY 
    high_value_customer_count DESC, total_supply_cost_from_high_value_customers DESC;
