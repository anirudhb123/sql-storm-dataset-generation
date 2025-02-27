WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
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
        cus.c_custkey, 
        cus.c_name, 
        cus.total_orders, 
        cus.total_spent,
        RANK() OVER (ORDER BY cus.total_spent DESC) AS order_rank
    FROM 
        CustomerOrderSummary cus
)
SELECT 
    r.r_name AS region_name,
    t.c_name AS top_customer,
    t.total_orders,
    t.total_spent,
    s.s_name AS top_supplier,
    s.total_supply_value
FROM 
    TopCustomers t
JOIN 
    RankedSuppliers s ON t.order_rank = 1
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = t.c_custkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    t.total_orders > 10
ORDER BY 
    r.r_name, t.total_spent DESC;
