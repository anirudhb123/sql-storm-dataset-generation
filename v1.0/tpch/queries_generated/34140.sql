WITH RECURSIVE supplier_rank AS (
    SELECT 
        s_suppkey,
        s_name,
        s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM 
        supplier
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
lineitem_summary AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS revenue,
        COUNT(l_linenumber) AS total_items,
        MAX(l_shipdate) AS latest_shipdate
    FROM 
        lineitem
    GROUP BY 
        l_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(co.total_spent) AS total_revenue,
    SUM(ls.revenue) AS lineitem_revenue,
    AVG(CASE 
        WHEN sr.rank IS NULL THEN 0 
        ELSE sr.rank 
    END) AS avg_supplier_rank
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    supplier_rank sr ON s.s_suppkey = sr.s_suppkey
LEFT JOIN 
    customer_orders co ON s.s_nationkey = co.c_custkey
LEFT JOIN 
    lineitem_summary ls ON co.c_custkey = ls.l_orderkey
GROUP BY 
    r.r_name
HAVING 
    SUM(ls.total_items) > 0 AND
    COUNT(DISTINCT co.c_custkey) > 10
ORDER BY 
    total_revenue DESC;
