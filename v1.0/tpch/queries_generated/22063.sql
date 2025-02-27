WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -12, CURRENT_DATE)
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp) 
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    COALESCE(ps.ps_availqty, 0) AS available_quantity,
    o.o_orderkey,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finished'
        WHEN o.o_orderstatus IS NULL THEN 'Unknown'
        ELSE 'Pending'
    END AS order_status,
    CASE 
        WHEN orders_in_last_year.total_orders > 0 THEN 'Regular' 
        ELSE 'Occasional' 
    END AS customer_type,
    s.s_suppkey,
    s.s_name,
    SUM(l.l_discount) OVER (PARTITION BY s.s_suppkey ORDER BY l.l_extendedprice) AS cumulative_discount
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedOrders o ON ps.ps_supplycost = o.o_orderkey
LEFT JOIN 
    HighValueSuppliers s ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    CustomerOrders orders_in_last_year ON orders_in_last_year.c_custkey = o.o_custkey
JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
WHERE 
    (p.p_size BETWEEN 10 AND 30 OR p.p_retailprice > 50) 
    AND (s.s_name LIKE '%Corp%' OR s.s_name IS NULL)
ORDER BY 
    p.p_name, o.o_orderkey DESC;
