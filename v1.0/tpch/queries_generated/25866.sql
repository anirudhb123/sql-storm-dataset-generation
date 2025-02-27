WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_brand AS part_brand,
        p.p_container AS part_container,
        CONCAT(p.p_name, ' - ', p.p_brand) AS full_part_description
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_key,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        AVG(l.l_quantity) AS avg_line_quantity
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, o.o_orderkey
),
RegionStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
)
SELECT 
    sp.supplier_name,
    sp.full_part_description,
    co.customer_name,
    co.total_order_value,
    rs.region_name,
    rs.nation_count,
    rs.total_available_quantity,
    LENGTH(sp.full_part_description) AS description_length
FROM 
    SupplierParts sp
JOIN 
    CustomerOrders co ON sp.part_name LIKE '%' || co.customer_name || '%'
JOIN 
    RegionStats rs ON LENGTH(sp.part_container) = rs.nation_count
ORDER BY 
    co.total_order_value DESC, rs.total_available_quantity ASC;
