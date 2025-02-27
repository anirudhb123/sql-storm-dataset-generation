WITH RECURSIVE order_hierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        0 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2020-01-01'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.level + 1
    FROM 
        orders o
    INNER JOIN 
        order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE 
        oh.level < 3
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity,
        MAX(l.l_shipdate) AS latest_shipdate
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sd.total_cost, 0) AS supplier_cost,
    ol.supplier_count,
    ol.total_revenue,
    ol.total_quantity,
    ol.latest_shipdate
FROM 
    part p
LEFT JOIN 
    supplier_details sd ON sd.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey = p.p_partkey 
        ORDER BY 
            ps.ps_supplycost 
        LIMIT 1
    )
LEFT JOIN 
    lineitem_summary ol ON ol.l_orderkey IN (
        SELECT 
            lo.o_orderkey 
        FROM 
            orders lo 
        WHERE 
            lo.o_orderkey IN (SELECT o_orderkey FROM order_hierarchy)
    )
WHERE 
    (p.p_size BETWEEN 1 AND 50) 
    AND (sd.total_cost IS NULL OR sd.total_cost > 1000)
ORDER BY 
    p.p_partkey DESC;
