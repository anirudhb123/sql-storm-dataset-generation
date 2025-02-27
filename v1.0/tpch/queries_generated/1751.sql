WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
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
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY total_supply_cost DESC) AS rn
    FROM 
        SupplierStats s
)
SELECT 
    c.c_name AS customer_name,
    c.total_spent AS total_spent,
    s.s_name AS supplier_name,
    ss.total_supply_cost,
    cs.order_count,
    COALESCE((SELECT AVG(l_extendedprice) 
              FROM lineitem l 
              WHERE l.l_suppkey = s.s_suppkey), 0) AS avg_extended_price
FROM 
    CustomerOrders c 
JOIN 
    orders o ON c.c_custkey = o.o_custkey 
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey 
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
LEFT JOIN 
    TopSuppliers s ON ps.ps_suppkey = s.s_suppkey 
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey 
WHERE 
    c.order_count > 5 AND 
    (ss.total_supply_cost IS NULL OR ss.total_supply_cost > 10000)
ORDER BY 
    total_spent DESC 
LIMIT 10;
