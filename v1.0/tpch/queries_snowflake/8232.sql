WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate 
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
OrderLineItems AS (
    SELECT 
        co.c_custkey, 
        co.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
    FROM 
        CustomerOrders co 
    JOIN 
        lineitem l ON co.o_orderkey = l.l_orderkey 
    GROUP BY 
        co.c_custkey, co.o_orderkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(oli.total_revenue) AS total_spent 
    FROM 
        CustomerOrders co 
    JOIN 
        OrderLineItems oli ON co.c_custkey = oli.c_custkey 
    JOIN 
        customer c ON co.c_custkey = c.c_custkey 
    GROUP BY 
        c.c_custkey, c.c_name 
    ORDER BY 
        total_spent DESC 
    LIMIT 10
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        p.p_name, 
        s.s_name, 
        s.s_acctbal 
    FROM 
        partsupp ps 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey 
    WHERE 
        ps.ps_availqty > 0
)
SELECT 
    tc.c_custkey, 
    tc.c_name, 
    ps.p_name, 
    SUM(oli.total_revenue) AS total_revenue_per_customer_part, 
    COUNT(*) AS num_suppliers 
FROM 
    TopCustomers tc 
JOIN 
    OrderLineItems oli ON tc.c_custkey = oli.c_custkey 
JOIN 
    PartSuppliers ps ON oli.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey) 
GROUP BY 
    tc.c_custkey, tc.c_name, ps.p_name 
ORDER BY 
    total_revenue_per_customer_part DESC;