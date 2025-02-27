WITH nation_supplier AS (
    SELECT 
        n.n_name AS nation_name,
        s.s_suppkey AS supplier_id,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        n.n_name, s.s_suppkey
),
order_summary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS number_of_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        c.c_custkey
),
supplier_rank AS (
    SELECT 
        nation_name,
        supplier_id,
        total_cost,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_cost DESC) AS supplier_rank
    FROM 
        nation_supplier
),
top_suppliers AS (
    SELECT 
        ns.nation_name,
        ns.supplier_id,
        ns.total_cost
    FROM 
        supplier_rank ns
    WHERE 
        ns.supplier_rank <= 5
)
SELECT 
    os.c_custkey,
    ts.nation_name,
    ts.supplier_id,
    ts.total_cost,
    os.total_order_value,
    os.number_of_orders
FROM 
    order_summary os
JOIN 
    top_suppliers ts ON ts.nation_name IN (
        SELECT n.n_name 
        FROM nation n 
        WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = os.c_custkey)
    )
ORDER BY 
    os.total_order_value DESC, ts.total_cost DESC;
