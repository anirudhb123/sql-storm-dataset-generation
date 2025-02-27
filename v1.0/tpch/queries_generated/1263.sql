WITH customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
supplier_parts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS rank_supply
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
top_customers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        co.total_orders
    FROM 
        customer_orders co
    WHERE 
        co.rank_spent <= 5
),
top_suppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_available,
        sp.avg_cost
    FROM 
        supplier_parts sp
    WHERE 
        sp.rank_supply <= 5
)
SELECT 
    tc.c_name AS customer_name,
    tc.total_spent,
    ts.s_name AS supplier_name,
    ts.total_available,
    CASE 
        WHEN ts.avg_cost IS NULL THEN 'No Cost Available'
        ELSE CONCAT('$', FORMAT(ts.avg_cost, 2))
    END AS avg_supply_cost
FROM 
    top_customers tc
FULL OUTER JOIN 
    top_suppliers ts ON tc.total_spent > 1000 OR ts.total_available > 0
WHERE 
    tc.total_orders >= 2 OR ts.avg_cost < 50.00
ORDER BY 
    tc.total_spent DESC, ts.total_available DESC;
