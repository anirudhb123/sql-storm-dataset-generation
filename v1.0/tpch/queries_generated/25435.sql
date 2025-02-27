WITH PartAggregation AS (
    SELECT 
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(p.p_retailprice) AS avg_retail_price,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_type
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    pa.p_type,
    pa.unique_suppliers,
    pa.total_available_quantity,
    pa.avg_retail_price,
    pa.part_names,
    co.total_orders,
    co.total_spent,
    co.last_order_date
FROM 
    PartAggregation pa
LEFT JOIN 
    CustomerOrders co ON pa.unique_suppliers > 5
ORDER BY 
    pa.total_available_quantity DESC, 
    co.total_spent DESC;
