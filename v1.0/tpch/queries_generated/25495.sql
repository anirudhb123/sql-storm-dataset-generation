WITH string_aggregates AS (
    SELECT 
        p.p_partkey,
        CONCAT('Part: ', p.p_name, '; Manufacturer: ', p.p_mfgr, '; Brand: ', p.p_brand) AS part_info,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nations
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        p.p_partkey
),
order_details AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        STRING_AGG(DISTINCT l.l_shipmode, ', ') AS shipping_modes,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    sa.p_partkey,
    sa.part_info,
    sa.suppliers,
    od.o_orderkey,
    od.o_orderdate,
    od.shipping_modes,
    od.total_revenue
FROM 
    string_aggregates sa
LEFT JOIN 
    order_details od ON sa.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')))
WHERE 
    od.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    sa.p_partkey, od.o_orderdate DESC;
