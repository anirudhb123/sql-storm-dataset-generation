WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS num_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
lineitem_stats AS (
    SELECT 
        l.l_orderkey,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS average_price,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_name,
    cs.total_orders,
    ss.s_name,
    ss.total_supply_cost,
    ls.average_price,
    ls.item_count
FROM 
    customer_orders cs
JOIN 
    supplier_summary ss ON ss.part_count > 5
LEFT JOIN 
    lineitem_stats ls ON ls.l_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_custkey = cs.c_custkey)
WHERE 
    cs.total_orders > (SELECT AVG(total_orders) FROM customer_orders) 
    AND ss.total_supply_cost IS NOT NULL
ORDER BY 
    ss.total_supply_cost DESC, cs.total_orders DESC;
