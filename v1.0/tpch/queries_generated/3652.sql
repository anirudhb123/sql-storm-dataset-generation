WITH supplier_summary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
order_details AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    COALESCE(ss.part_count, 0) AS supplier_part_count,
    COALESCE(ss.total_available, 0) AS supplier_total_available,
    COALESCE(ss.avg_supply_cost, 0) AS supplier_avg_supply_cost,
    COALESCE(co.total_orders, 0) AS customer_order_count,
    COALESCE(co.total_spent, 0) AS customer_total_spent,
    od.total_line_item_value,
    od.line_item_count
FROM 
    customer_orders co 
FULL OUTER JOIN 
    supplier_summary ss ON co.c_custkey = ss.s_suppkey 
FULL OUTER JOIN 
    order_details od ON co.total_orders = od.line_item_count
WHERE 
    (co.total_orders > 0 OR ss.s_suppkey IS NULL) AND 
    (ss.part_count IS NOT NULL OR co.custkey IS NULL)
ORDER BY 
    cs.c_custkey;
