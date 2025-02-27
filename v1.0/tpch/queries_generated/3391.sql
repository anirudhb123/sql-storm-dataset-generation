WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)

SELECT 
    c.c_name,
    COALESCE(co.total_spent, 0) AS total_spent,
    COALESCE(sp.total_supply_value, 0) AS supplier_value,
    COUNT(od.o_orderkey) AS completed_order_count,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY COALESCE(co.total_spent, 0) DESC) AS rank
FROM 
    HighValueCustomers c
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    SupplierParts sp ON sp.total_supply_value > 10000
LEFT JOIN 
    OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
GROUP BY 
    c.c_custkey, c.c_name, co.total_spent, sp.total_supply_value
HAVING 
    COUNT(od.o_orderkey) > 0
ORDER BY 
    rank ASC, total_spent DESC;
