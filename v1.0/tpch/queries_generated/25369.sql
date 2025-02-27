WITH BrandCounts AS (
    SELECT 
        p_brand, 
        COUNT(DISTINCT p_partkey) AS brand_part_count
    FROM 
        part
    GROUP BY 
        p_brand
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        CONCAT(c.c_name, ' from ', c.c_address) AS customer_info, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address
),
SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    bc.p_brand,
    bc.brand_part_count,
    COALESCE(c.total_spent, 0) AS total_spent_by_customer,
    sp.supplied_parts_count
FROM 
    BrandCounts bc
LEFT JOIN 
    CustomerOrders c ON c.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_returnflag = 'R')
JOIN 
    SupplierParts sp ON sp.supplied_parts_count > 10
ORDER BY 
    bc.brand_part_count DESC, total_spent_by_customer DESC;
