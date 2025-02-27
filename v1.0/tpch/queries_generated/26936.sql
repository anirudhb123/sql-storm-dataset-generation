WITH part_supplier_info AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' supplied by ', s.s_name, ' with available quantity ', CAST(ps.ps_availqty AS VARCHAR), ' at a supply cost of ', FORMAT(ps.ps_supplycost, 'C')) AS detailed_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT CONCAT('Order ', o.o_orderkey, ': $', FORMAT(o.o_totalprice, 'C')), '; ') AS order_details
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    psi.detailed_info,
    cos.c_name,
    cos.total_orders,
    cos.total_spent,
    cos.order_details
FROM 
    part_supplier_info psi
JOIN 
    customer_order_summary cos ON cos.total_orders > 0
WHERE 
    LOWER(psi.supplier_name) LIKE '%global%' AND 
    psi.ps_availqty > 10
ORDER BY 
    cos.total_spent DESC, psi.p_partkey;
