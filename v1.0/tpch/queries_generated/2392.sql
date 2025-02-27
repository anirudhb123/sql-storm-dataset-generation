WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS spending_rank
    FROM 
        CustomerOrders co
)
SELECT 
    tc.c_name AS customer_name,
    COALESCE(ss.s_name, 'No Supplier') AS supplier_name,
    ss.total_available,
    ss.average_cost,
    CASE 
        WHEN tc.spending_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    TopCustomers tc
LEFT JOIN 
    lineitem li ON li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey)
LEFT JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier ss ON ps.ps_suppkey = ss.s_suppkey
WHERE 
    tc.total_spent > 1000
ORDER BY 
    tc.total_spent DESC, supplier_name ASC;
