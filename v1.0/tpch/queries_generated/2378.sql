WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
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
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
EnhancedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity * (1 - l.l_discount) AS net_price,
        DENSE_RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM 
        lineitem l
)

SELECT 
    c.c_name,
    co.total_spent,
    sp.total_parts,
    COALESCE(SUM(e.net_price), 0) AS total_net_price,
    COUNT(DISTINCT e.l_orderkey) AS distinct_orders,
    AVG(e.price_rank) AS average_price_rank
FROM 
    CustomerOrders co
JOIN 
    SupplierParts sp ON co.c_custkey IS NOT NULL AND sp.total_parts > 10
LEFT JOIN 
    EnhancedLineItems e ON co.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = e.l_orderkey)
WHERE 
    co.total_orders > 5 
    AND sp.total_value IS NOT NULL
GROUP BY 
    c.c_name, co.total_spent, sp.total_parts
HAVING 
    AVG(e.price_rank) < 3
ORDER BY 
    co.total_spent DESC, sp.total_parts ASC;
