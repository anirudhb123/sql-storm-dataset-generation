
WITH supplier_totals AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_totals AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
customer_order_stats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(ot.total_order_value), 0) AS customer_total_orders,
        COUNT(DISTINCT ot.o_orderkey) AS number_of_orders
    FROM 
        customer c
    LEFT JOIN 
        order_totals ot ON c.c_custkey = ot.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cr.r_name AS region_name,
    SUM(cos.customer_total_orders) AS total_order_value_by_region,
    AVG(cos.number_of_orders) AS avg_orders_per_customer,
    COUNT(DISTINCT st.s_suppkey) AS supplier_count,
    LISTAGG(DISTINCT st.s_name, ', ') WITHIN GROUP (ORDER BY st.s_name) AS supplier_names
FROM 
    region cr
JOIN 
    nation n ON cr.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer_order_stats cos ON cos.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = n.n_nationkey
    )
LEFT JOIN 
    supplier st ON n.n_nationkey = st.s_nationkey
WHERE 
    (st.s_acctbal IS NULL OR st.s_acctbal > 1000) AND
    cr.r_name IS NOT NULL
GROUP BY 
    cr.r_name
HAVING 
    SUM(cos.customer_total_orders) > 0
ORDER BY 
    total_order_value_by_region DESC;
