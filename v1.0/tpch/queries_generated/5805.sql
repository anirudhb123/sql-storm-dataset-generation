WITH supplier_part_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_order_summary AS (
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
nation_supplier_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ss.total_available_quantity) AS total_part_quantity,
        SUM(ss.total_supply_cost) AS total_supply_cost
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        supplier_part_summary ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name AS nation_name,
    ns.supplier_count,
    ns.total_part_quantity,
    ns.total_supply_cost,
    cs.total_orders,
    cs.total_spent
FROM 
    nation_supplier_summary ns
LEFT JOIN 
    customer_order_summary cs ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT MIN(c2.c_custkey) FROM customer c2 WHERE c2.c_nationkey = ns.n_nationkey))
ORDER BY 
    ns.n_name, cs.total_spent DESC;
