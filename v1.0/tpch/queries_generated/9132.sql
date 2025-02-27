WITH CustomerOrderTotals AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cot.total_spent,
        cot.order_count,
        RANK() OVER (ORDER BY cot.total_spent DESC) AS spending_rank
    FROM 
        CustomerOrderTotals cot
    JOIN 
        customer c ON cot.c_custkey = c.c_custkey
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_spent,
    tc.order_count,
    r.r_name AS customer_region,
    COUNT(DISTINCT l.l_orderkey) AS total_line_items,
    AVG(l.l_extendedprice) AS avg_lineitem_price,
    SUM(l.l_discount) AS total_discounted_price
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    tc.spending_rank <= 10
GROUP BY 
    tc.c_custkey, tc.c_name, r.r_name
ORDER BY 
    tc.total_spent DESC;
