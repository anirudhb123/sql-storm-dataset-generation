
WITH SupplierCostSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        cus.c_custkey,
        cus.c_name
    FROM 
        CustomerOrders cus
    WHERE 
        cus.total_order_value > (SELECT AVG(total_order_value) FROM CustomerOrders)
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_supply_cost
    FROM 
        SupplierCostSummary s
    ORDER BY 
        s.total_supply_cost DESC
    LIMIT 10
)
SELECT 
    h.c_name AS customer_name,
    h.c_custkey AS customer_key,
    t.s_name AS supplier_name,
    t.s_suppkey AS supplier_key,
    t.total_supply_cost AS supplier_cost
FROM 
    HighValueCustomers h
JOIN 
    TopSuppliers t ON t.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey 
        WHERE o.o_custkey = h.c_custkey
    )
ORDER BY 
    h.c_name, t.total_supply_cost DESC;
