WITH ConcatenatedData AS (
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' (', p.p_container, ')') AS full_part_description,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        p.p_partkey, full_part_description, s.s_name, c.c_name, r.r_name
)
SELECT 
    full_part_description,
    supplier_name,
    customer_name,
    region_name,
    total_revenue
FROM 
    ConcatenatedData
WHERE 
    total_revenue > (
        SELECT AVG(total_revenue) FROM ConcatenatedData
    )
ORDER BY 
    total_revenue DESC;
