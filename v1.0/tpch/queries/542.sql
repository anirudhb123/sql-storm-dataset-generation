WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
supplier_part_summary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS total_lines
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.rnk,
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(p.p_name, 'Unknown Part') AS part_name,
    s.supplier_count,
    COALESCE(l.total_revenue, 0) AS total_revenue,
    COALESCE(l.total_lines, 0) AS total_lines,
    CASE 
        WHEN r.o_totalprice > 1000 THEN 'High Value'
        WHEN r.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    ranked_orders r
LEFT JOIN 
    lineitem_summary l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    supplier_part_summary s ON s.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MIN(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = s.ps_partkey))
LEFT JOIN 
    part p ON p.p_partkey = s.ps_partkey
WHERE 
    r.rnk <= 10
ORDER BY 
    r.o_orderdate DESC, r.o_orderkey;