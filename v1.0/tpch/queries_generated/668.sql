WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
order_line_item_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    c.c_name,
    c.c_acctbal,
    cus.order_count,
    cus.total_spent,
    ol.total_revenue,
    ol.item_count,
    COALESCE(rs.s_name, 'No Supplier Available') AS supplier_name,
    rs.rank
FROM 
    customer_order_summary cus
JOIN 
    customer c ON cus.c_custkey = c.c_custkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    order_line_item_summary ol ON o.o_orderkey = ol.l_orderkey
LEFT JOIN 
    ranked_suppliers rs ON ol.total_revenue > 1000 AND rs.rank = 1
WHERE 
    cus.total_spent IS NOT NULL
ORDER BY 
    cus.order_count DESC, cus.total_spent DESC;
