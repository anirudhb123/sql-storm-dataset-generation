WITH SupplierAgg AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
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
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name
    FROM 
        SupplierAgg s 
    WHERE 
        s.total_cost > (SELECT AVG(total_cost) FROM SupplierAgg)
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name
    FROM 
        CustomerOrders c 
    WHERE 
        c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    hvs.s_suppkey, 
    hvs.s_name, 
    hvc.c_custkey, 
    hvc.c_name 
FROM 
    HighValueSuppliers hvs
JOIN 
    HighValueCustomers hvc ON hvs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem li ON ps.ps_partkey = li.l_partkey JOIN orders o ON li.l_orderkey = o.o_orderkey WHERE o.o_orderstatus = 'F')
ORDER BY 
    hvs.s_suppkey, hvc.c_custkey;
