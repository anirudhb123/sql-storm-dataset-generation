WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        c.c_name AS customer_name,
        l.o_orderkey,
        l.l_quantity,
        l.l_extendedprice,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        l.l_shipmode = 'AIR'
        AND p.p_brand LIKE 'Brand#%'
        AND c.c_mktsegment = 'AUTOMOBILE'
)
SELECT 
    rs.s_name,
    SUM(rs.l_quantity) AS total_quantity,
    SUM(rs.l_extendedprice) AS total_extended_price
FROM 
    RankedSuppliers rs
WHERE 
    rs.rn <= 5
GROUP BY 
    rs.s_name
HAVING 
    SUM(rs.l_quantity) > 1000
ORDER BY 
    total_extended_price DESC;
