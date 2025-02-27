WITH supplier_summary AS (
    SELECT 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_availqty) AS total_available_qty, 
        SUM(ps.ps_supplycost) AS total_supply_cost, 
        STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')'), ', ') AS supplied_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, n.n_name
),
customer_summary AS (
    SELECT 
        c.c_name, 
        n.n_name AS nation_name, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name, n.n_name
)
SELECT 
    ss.s_name AS supplier_name, 
    ss.nation_name AS supplier_nation, 
    ss.total_available_qty, 
    ss.total_supply_cost, 
    cs.c_name AS customer_name, 
    cs.total_orders, 
    cs.total_spent
FROM 
    supplier_summary ss
JOIN 
    customer_summary cs ON ss.nation_name = cs.nation_name
WHERE 
    ss.total_supply_cost > 1000 AND cs.total_spent < 5000
ORDER BY 
    ss.total_available_qty DESC, cs.total_spent ASC;
