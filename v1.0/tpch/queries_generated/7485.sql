WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 10
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
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS number_of_nations,
    SUM(cp.total_available_qty) AS total_available_parts,
    COUNT(DISTINCT ts.s_suppkey) AS total_suppliers,
    SUM(co.total_spent) AS total_sales
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedParts cp ON cp.p_partkey IN (
        SELECT 
            ps.ps_partkey
        FROM 
            partsupp ps
    )
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey IN (
        SELECT 
            ps.ps_suppkey
        FROM 
            partsupp ps
    )
LEFT JOIN 
    CustomerOrders co ON co.c_custkey IN (
        SELECT 
            o.o_custkey
        FROM 
            orders o
    )
GROUP BY 
    r.r_name
ORDER BY 
    total_sales DESC
LIMIT 10;
