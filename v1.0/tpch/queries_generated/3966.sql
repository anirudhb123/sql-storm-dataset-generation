WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_orders,
        c.total_spent
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, p.p_comment
)
SELECT 
    tc.c_name AS TopCustomer,
    ps.p_name AS PartName,
    ps.total_avail_qty AS AvailableQuantity,
    rs.total_supply_cost AS TotalSupplyCost
FROM 
    TopCustomers tc
JOIN 
    lineitem li ON li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey)
JOIN 
    PartDetails ps ON ps.p_partkey = li.l_partkey
JOIN 
    RankedSuppliers rs ON li.l_suppkey = rs.s_suppkey
WHERE 
    ps.total_avail_qty IS NOT NULL
ORDER BY 
    tc.total_spent DESC, rs.total_supply_cost DESC
LIMIT 10;
