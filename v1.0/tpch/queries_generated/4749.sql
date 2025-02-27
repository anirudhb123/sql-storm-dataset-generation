WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpenders AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.total_spent
    FROM 
        CustomerOrders cust
    WHERE 
        cust.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    COALESCE(ns.r_name, 'Unknown Region') AS region_name,
    hs.c_name AS high_spender,
    s.s_name AS supplier_name,
    rs.total_cost AS supplier_total_cost,
    hs.total_spent AS customer_total_spent
FROM 
    HighSpenders hs
LEFT OUTER JOIN 
    supplier s ON hs.c_custkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_nationkey = rs.s_nationkey
LEFT JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
WHERE 
    s.s_comment IS NOT NULL
ORDER BY 
    ns.r_name, hs.total_spent DESC, rs.total_cost DESC;
