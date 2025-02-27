WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpenders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        co.total_orders
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    hs.c_name AS customer_name,
    hs.total_spent,
    hs.total_orders,
    sp.s_name AS supplier_name,
    sp.part_count,
    sp.total_supplycost
FROM 
    HighSpenders hs
JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = hs.c_custkey)
JOIN 
    partsupp ps ON ps.ps_partkey = l.l_partkey
JOIN 
    supplier sp ON sp.s_suppkey = ps.ps_suppkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    hs.total_spent DESC, sp.total_supplycost DESC
LIMIT 100;
