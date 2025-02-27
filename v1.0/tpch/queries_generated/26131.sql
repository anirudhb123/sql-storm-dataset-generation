WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        COUNT(ps.ps_availqty) AS available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT p.p_type, ', ') AS part_types,
        STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_id,
        o.o_totalprice AS total_price,
        DATE_PART('year', o.o_orderdate) AS order_year,
        STRING_AGG(DISTINCT o.o_comment, '; ') AS order_comments
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT 
    sp.supplier_name,
    COUNT(DISTINCT co.order_id) AS order_count,
    SUM(co.total_price) AS total_revenue,
    MAX(co.order_year) AS last_order_year,
    STRING_AGG(DISTINCT sp.part_types, ', ') AS all_part_types,
    STRING_AGG(DISTINCT co.order_comments, '; ') AS all_order_comments
FROM 
    SupplierParts sp
LEFT JOIN 
    CustomerOrders co ON sp.supplier_name LIKE '%' || co.customer_name || '%'
GROUP BY 
    sp.supplier_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
