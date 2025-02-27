WITH part_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.total_available_qty,
    ps.avg_supply_cost,
    co.c_custkey,
    co.c_name,
    co.total_orders,
    co.total_spent
FROM 
    part_summary ps
JOIN 
    customer_orders co ON ps.p_brand = ANY(STRING_TO_ARRAY(co.c_mktsegment, ', '))
ORDER BY 
    total_spent DESC, total_available_qty DESC;
