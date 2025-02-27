WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_supply_value DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_name, 
    rp.total_avail_qty, 
    rp.total_supply_cost, 
    ts.s_name AS top_supplier, 
    co.c_name AS customer_name, 
    co.total_orders, 
    co.total_spent 
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.rank = 1
JOIN 
    CustomerOrders co ON co.total_spent > 1000
WHERE 
    rp.total_supply_cost > 5000
ORDER BY 
    rp.total_supply_cost DESC, 
    co.total_spent DESC;
