WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spender_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
TopSpenders AS (
    SELECT 
        COALESCE(cu.c_name, 'Unknown') AS customer_name,
        COALESCE(n.n_name, 'Unknown') AS nation_name,
        co.total_spent,
        co.total_orders
    FROM 
        CustomerOrders co
    LEFT JOIN 
        nation n ON co.cust_nationkey = n.n_nationkey
    LEFT JOIN 
        customer cu ON co.c_custkey = cu.c_custkey
    WHERE 
        co.spender_rank <= 10
)
SELECT 
    ts.customer_name,
    ts.nation_name,
    ts.total_spent,
    ts.total_orders,
    CASE 
        WHEN ts.total_orders > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type,
    STRING_AGG(DISTINCT p.p_name, ', ') AS purchased_parts
FROM 
    TopSpenders ts
LEFT JOIN 
    orders o ON ts.custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    ts.customer_name, ts.nation_name, ts.total_spent, ts.total_orders
ORDER BY 
    ts.total_spent DESC;
