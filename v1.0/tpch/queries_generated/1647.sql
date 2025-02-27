WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) as rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
supplier_summary AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
part_sales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
)


SELECT 
    r.r_name,
    COALESCE(ss.total_parts, 0) AS supplier_part_count,
    COALESCE(ps.total_sales, 0) AS part_total_sales,
    oo.o_orderdate,
    oo.o_totalprice
FROM 
    region r
LEFT JOIN 
    supplier_summary ss ON ss.total_parts > 0
LEFT JOIN 
    part_sales ps ON ps.total_sales > 0
LEFT JOIN 
    ranked_orders oo ON oo.rn = 1 AND ss.total_parts > 0
WHERE 
    r.r_regionkey IS NOT NULL
ORDER BY 
    r.r_name, oo.o_totalprice DESC
FETCH FIRST 50 ROWS ONLY;
