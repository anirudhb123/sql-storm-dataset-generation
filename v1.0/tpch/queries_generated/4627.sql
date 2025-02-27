WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderLineAggregation AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2023-10-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    ss.total_cost,
    ola.total_line_revenue,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Value'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment,
    RANK() OVER (PARTITION BY cs.c_custkey ORDER BY cs.total_spent DESC) AS spending_rank
FROM 
    CustomerOrders cs
LEFT JOIN 
    SupplierStats ss ON cs.total_orders > 5
LEFT JOIN 
    OrderLineAggregation ola ON ola.l_orderkey IN 
        (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
WHERE 
    ss.total_parts IS NOT NULL OR cs.total_orders IS NULL
ORDER BY 
    cs.total_spent DESC, ss.total_cost ASC;
