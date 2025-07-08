
WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LISTAGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS suppliers,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        p.p_partkey, p.p_name
),
RankedSuppliers AS (
    SELECT 
        p_partkey,
        p_name,
        suppliers,
        customer_count,
        total_quantity,
        ROW_NUMBER() OVER (ORDER BY customer_count DESC, total_quantity DESC) AS rn
    FROM 
        StringAggregation
)
SELECT 
    p_partkey,
    p_name,
    suppliers,
    customer_count,
    total_quantity
FROM 
    RankedSuppliers
WHERE 
    rn <= 10;
