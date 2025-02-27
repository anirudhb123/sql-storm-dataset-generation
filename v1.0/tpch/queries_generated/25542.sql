WITH part_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        MAX(CASE WHEN p.p_size IS NOT NULL THEN p.p_size ELSE 0 END) AS max_size,
        STRING_AGG(DISTINCT s.s_name, '; ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS lineitem_count,
        STRING_AGG(DISTINCT p.p_name, ', ') AS ordered_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.p_brand,
    ps.supplier_count,
    ps.max_size,
    ps.supplier_names,
    os.o_orderkey,
    os.o_totalprice,
    os.o_orderdate,
    os.lineitem_count,
    os.ordered_parts
FROM 
    part_summary ps
LEFT JOIN 
    order_summary os ON ps.p_partkey IN (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l 
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey 
        WHERE 
            o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    )
ORDER BY 
    ps.p_partkey, os.o_orderdate DESC;
