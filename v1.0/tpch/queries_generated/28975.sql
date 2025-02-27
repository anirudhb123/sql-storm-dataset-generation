WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_name, 
        ps.ps_supplycost, 
        RANK() OVER (PARTITION BY p.p_name ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
StringAggregated AS (
    SELECT 
        p.p_type, 
        STRING_AGG(CONCAT(s.s_name, ' (Cost: ', ps.ps_supplycost, ')'), '; ') AS suppliers 
    FROM 
        RankedSuppliers rs
    JOIN 
        part p ON rs.p_name = p.p_name 
    JOIN 
        partsupp ps ON rs.ps_partkey = ps.ps_partkey 
    WHERE 
        rs.rank <= 3 -- Select top 3 cheapest suppliers for each part
    GROUP BY 
        p.p_type
)
SELECT 
    r.r_name AS region_name, 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    AVG(o.o_totalprice) AS average_order_value,
    sa.p_type,
    sa.suppliers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    customer c ON s.s_suppkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    StringAggregated sa ON sa.p_type IN (SELECT DISTINCT p_type FROM part)
GROUP BY 
    r.r_name, sa.p_type
ORDER BY 
    r.r_name, average_order_value DESC;
