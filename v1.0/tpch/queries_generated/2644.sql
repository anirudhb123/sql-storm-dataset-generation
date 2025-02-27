WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
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
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
nation_supplier AS (
    SELECT 
        n.n_name,
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
ranked_partners AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_supply_cost,
        part_count,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS supply_rank
    FROM 
        supplier_stats s
),
final_report AS (
    SELECT 
        n.n_name AS nation,
        c.c_custkey AS customer_key,
        coalesce(cs.total_order_value, 0) AS total_order_value,
        cs.order_count,
        coalesce(rs.total_supply_cost, 0) AS total_supply_cost,
        rs.part_count,
        ns.supplier_count
    FROM 
        nation_supplier ns
    LEFT JOIN 
        customer_orders cs ON ns.n_nationkey = cs.c_custkey
    LEFT JOIN 
        ranked_partners rs ON rs.s_supply_rank <= ns.supplier_count
)

SELECT 
    f.nation,
    f.customer_key,
    f.total_order_value,
    f.order_count,
    f.total_supply_cost,
    f.part_count,
    f.supplier_count
FROM 
    final_report f
WHERE 
    f.total_order_value > (SELECT AVG(total_order_value) FROM customer_orders)
ORDER BY 
    f.total_order_value DESC, 
    f.supplier_count DESC;
