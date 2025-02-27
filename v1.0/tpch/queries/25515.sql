WITH SupplierPartCounts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS part_count,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    sp.s_name AS supplier_name,
    sp.part_count,
    sp.part_names,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent
FROM 
    SupplierPartCounts sp
JOIN 
    CustomerOrderStats co ON sp.s_suppkey = (SELECT ps.ps_suppkey 
                                               FROM partsupp ps 
                                               ORDER BY RANDOM() LIMIT 1)
ORDER BY 
    co.total_spent DESC, sp.part_count DESC
LIMIT 10;
