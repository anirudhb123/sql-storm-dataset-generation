WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
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
    WHERE 
        o.o_orderstatus = 'O'  -- Only completed orders
    GROUP BY 
        c.c_custkey, c.c_name
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
    p.p_name,
    r.r_name AS region_name,
    COALESCE(RS.s_name, 'No Supplier') AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    COUNT(DISTINCT c.c_custkey) AS customer_count
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers RS ON ps.ps_suppkey = RS.s_suppkey AND RS.rnk = 1
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    HighValueCustomers hvc ON hvc.c_custkey = o.o_custkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, r.r_name, RS.s_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
