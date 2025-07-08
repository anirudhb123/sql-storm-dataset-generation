
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_address,
        rs.s_phone,
        rs.part_count,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 3
)
SELECT 
    t.s_name,
    t.s_address,
    '|' || LISTAGG(CONCAT('{"supplies": "', p.p_name, '"}'), ', ') || '|' AS parts_supplied,
    SUM(o.o_totalprice) AS total_orders,
    AVG(l.l_discount) AS avg_discount
FROM 
    TopSuppliers t
JOIN 
    partsupp ps ON t.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    t.s_name, t.s_address
ORDER BY 
    total_orders DESC;
