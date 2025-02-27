WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_brand AS brand,
        p.p_type AS type,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        STRING_AGG(DISTINCT p.p_comment, '; ') AS combined_comments
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, p.p_name, p.p_brand, p.p_type
),
RegionCustomers AS (
    SELECT 
        r.r_name AS region_name,
        c.c_name AS customer_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        STRING_AGG(DISTINCT c.c_comment, '; ') AS combined_customer_comments
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
    GROUP BY 
        r.r_name, c.c_name
)
SELECT 
    sp.supplier_name,
    sp.part_name,
    sp.brand,
    sp.type,
    sp.total_available_qty,
    sp.average_supply_cost,
    sp.combined_comments,
    rc.region_name,
    rc.customer_name,
    rc.total_orders,
    rc.combined_customer_comments
FROM 
    SupplierParts sp
JOIN 
    RegionCustomers rc ON sp.supplier_name = rc.customer_name
ORDER BY 
    sp.total_available_qty DESC, rc.total_orders DESC;
