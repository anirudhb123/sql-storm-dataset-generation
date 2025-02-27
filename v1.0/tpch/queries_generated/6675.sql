WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.custkey,
        c.name,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON c.c_custkey = co.c_custkey
    WHERE 
        co.total_spent > 10000
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 5
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 3000
)
SELECT 
    tc.rank,
    tc.name AS top_customer,
    tn.n_name AS supplier_nation,
    COUNT(h.vo_orderkey) AS high_value_orders_count
FROM 
    TopCustomers tc
CROSS JOIN 
    TopNations tn
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.custkey)
GROUP BY 
    tc.rank, tc.name, tn.n_name
ORDER BY 
    tc.rank, tn.n_name;
