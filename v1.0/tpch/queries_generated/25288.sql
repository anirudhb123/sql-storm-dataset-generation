WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT p.p_brand || ' - ' || p.p_name, ', ') AS part_details
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    s.s_suppkey,
    s.s_name,
    s.total_parts,
    s.total_available_quantity,
    s.total_supply_cost,
    s.part_details,
    o.o_orderkey,
    o.o_custkey,
    o.total_revenue,
    o.item_count,
    DATE_TRUNC('month', o.o_orderdate) AS order_month
FROM 
    supplier_summary s
JOIN 
    order_summary o ON s.total_parts > 0
ORDER BY 
    s.total_available_quantity DESC, o.total_revenue DESC;
