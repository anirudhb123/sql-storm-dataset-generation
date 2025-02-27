WITH PartSupplierSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT o.o_orderstatus) AS order_statuses
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name AS part_name,
    p.total_available_quantity,
    p.unique_suppliers,
    p.supplier_names,
    c.c_name AS customer_name,
    c.total_orders,
    c.total_spent,
    c.order_statuses
FROM 
    PartSupplierSummary p
JOIN 
    CustomerOrderSummary c ON p.unique_suppliers > 5 AND c.total_orders > 10
ORDER BY 
    p.total_available_quantity DESC, c.total_spent ASC;
