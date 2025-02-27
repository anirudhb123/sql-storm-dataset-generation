WITH supplier_details AS (
    SELECT 
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        CONCAT(s.s_name, ' (', n.n_name, ', ', r.r_name, ')') AS supplier_location
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
order_summaries AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
lineitem_analysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    sd.supplier_location,
    os.total_orders,
    os.total_spent,
    la.total_quantity,
    la.total_revenue,
    la.distinct_parts
FROM 
    supplier_details sd
JOIN 
    order_summaries os ON sd.s_acctbal > 1000
JOIN 
    lineitem_analysis la ON la.l_orderkey IN (SELECT o.o_orderkey FROM orders o JOIN customer c ON o.o_custkey = c.c_custkey WHERE c.c_acctbal > 500)
ORDER BY 
    total_spent DESC, total_revenue DESC;
