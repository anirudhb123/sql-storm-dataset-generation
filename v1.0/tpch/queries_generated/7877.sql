WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
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
    HAVING 
        COUNT(o.o_orderkey) > 10
)
SELECT 
    rp.p_name, 
    rp.p_brand, 
    rp.p_type, 
    ts.nation, 
    ts.total_supply, 
    co.c_name, 
    co.order_count, 
    co.total_spent
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.total_supply_cost > 10000
JOIN 
    CustomerOrders co ON co.total_spent > 1000
ORDER BY 
    rp.total_supply_cost DESC, co.total_spent DESC
LIMIT 50;
