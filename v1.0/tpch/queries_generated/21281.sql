WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey,
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'P')
),
customer_info AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        r.r_name AS region_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_order_value
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        ranked_orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, r.r_name
),
supplier_part AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
top_supp AS (
    SELECT 
        sp.s_suppkey, 
        sp.s_name, 
        sp.total_supply_value,
        DENSE_RANK() OVER (ORDER BY sp.total_supply_value DESC) AS value_rank
    FROM 
        supplier_part sp
    WHERE 
        sp.total_supply_value > 100000
),
final_selection AS (
    SELECT 
        ci.c_name, 
        ci.order_count, 
        ci.max_order_value, 
        ts.total_supply_value
    FROM 
        customer_info ci
    FULL OUTER JOIN 
        top_supp ts ON ci.order_count = (SELECT MAX(order_count) FROM customer_info) 
                     OR ts.total_supply_value = (SELECT MAX(total_supply_value) FROM top_supp)
)
SELECT 
    fs.c_name AS customer_name,
    fs.order_count AS total_orders,
    COALESCE(fs.max_order_value, 'No Orders') AS highest_order_value,
    COALESCE(fs.total_supply_value, 'No Suppliers') AS top_supplier_value
FROM 
    final_selection fs
WHERE 
    (fs.order_count IS NOT NULL AND fs.total_supply_value IS NOT NULL)
    OR (fs.order_count IS NULL AND fs.total_supply_value IS NULL)
ORDER BY 
    customer_name ASC NULLS LAST;
