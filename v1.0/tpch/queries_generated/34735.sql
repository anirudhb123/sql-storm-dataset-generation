WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        1 AS depth
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT 
        co.c_custkey,
        co.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        co.depth + 1
    FROM 
        CustomerOrders co
    JOIN 
        orders o ON co.o_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    s.s_name AS supplier,
    p.p_name AS part,
    SUM(COALESCE(ps.ps_availqty, 0)) AS total_available_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    COUNT(DISTINCT co.o_orderkey) AS order_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey = l.l_orderkey
WHERE 
    p.p_size > 20 AND 
    s.s_acctbal IS NOT NULL AND 
    l.l_shipmode IN ('AIR', 'GROUND')
GROUP BY 
    r.r_name, n.n_name, s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 50 AND 
    AVG(l.l_extendedprice * (1 - l.l_discount)) > 100
ORDER BY 
    region, nation, supplier, part;
