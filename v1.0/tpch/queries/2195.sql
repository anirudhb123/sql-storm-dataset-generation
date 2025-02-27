WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
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
        COUNT(*) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(total_cost) AS avg_supplier_cost,
    SUM(CASE WHEN lo.total_lines > 5 THEN 1 ELSE 0 END) AS large_orders,
    STRING_AGG(DISTINCT p.p_name, ', ') AS popular_parts
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    supplier_details sd ON s.s_suppkey = sd.s_suppkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    lineitem_summary lo ON o.o_orderkey = lo.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    r.r_name IS NOT NULL
    AND o.o_orderstatus = 'O'
    AND sd.total_cost IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    unique_customers DESC,
    avg_supplier_cost DESC
LIMIT 10;