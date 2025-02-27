WITH supplier_details AS (
    SELECT 
        s.s_name as supplier_name,
        n.n_name as nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, n.n_name
),
customer_order_summary AS (
    SELECT 
        c.c_name as customer_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT o.o_orderstatus, ', ') AS order_statuses
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    sd.supplier_name,
    sd.nation_name,
    sd.total_supply_value,
    sd.part_count,
    sd.part_names,
    cos.customer_name,
    cos.order_count,
    cos.total_spent,
    cos.order_statuses
FROM 
    supplier_details sd
LEFT JOIN 
    customer_order_summary cos ON sd.part_count > 5
WHERE 
    sd.total_supply_value > 10000
ORDER BY 
    sd.total_supply_value DESC, cos.total_spent ASC;
