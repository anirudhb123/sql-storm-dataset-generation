
WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS supplier_part_description
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_item_count,
        STRING_AGG(DISTINCT CONCAT(p.p_name, ' x', l.l_quantity), ', ') AS items_ordered
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    rp.r_name AS region_name,
    COUNT(DISTINCT co.c_custkey) AS unique_customers,
    SUM(co.total_order_value) AS total_revenue,
    COUNT(DISTINCT sp.s_suppkey) AS total_suppliers,
    STRING_AGG(DISTINCT co.items_ordered, '; ') AS top_items_ordered
FROM 
    region rp
JOIN 
    nation n ON rp.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplierParts sp ON s.s_suppkey = sp.s_suppkey
JOIN 
    CustomerOrderDetails co ON co.o_orderkey = sp.ps_supplycost  -- Corrected join condition
GROUP BY 
    rp.r_name
ORDER BY 
    total_revenue DESC;
