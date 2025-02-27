WITH RECURSIVE invoice_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rank_order,
        CASE 
            WHEN COUNT(l.l_linenumber) > 1 THEN 'MULTILINE'
            WHEN COUNT(l.l_linenumber) = 1 AND SUM(l.l_quantity) > 100 THEN 'BULK'
            ELSE 'SINGLELINE'
        END AS order_type
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.order_type,
        RANK() OVER (PARTITION BY order_type ORDER BY total_revenue DESC) AS rev_rank
    FROM 
        invoice_summary
    WHERE 
        total_revenue IS NOT NULL
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    os.order_type,
    os.total_revenue,
    COALESCE(n.n_name, 'UNKNOWN') AS nation_name,
    CASE 
        WHEN n.n_regionkey = 1 THEN 'North'
        WHEN n.n_regionkey = 2 THEN 'South'
        ELSE 'Other'
    END AS region_label,
    (SELECT 
        COUNT(*) 
     FROM 
        partsupp ps 
     WHERE 
        ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
     AND 
        ps.ps_availqty > 50) AS available_parts_count
FROM 
    ranked_orders os
JOIN 
    orders o ON os.o_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey) LIMIT 1)
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    os.rev_rank <= 10
    AND (n.n_comment LIKE '%excellent%' OR n.n_comment IS NULL)
ORDER BY 
    os.order_type, os.total_revenue DESC;
