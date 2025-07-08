WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
top_nations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        COUNT(DISTINCT cs.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        customer cs ON n.n_nationkey = cs.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
order_totals AS (
    SELECT 
        o.o_custkey, 
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
)
SELECT 
    ns.n_name AS nation_name,
    ts.s_name AS supplier_name,
    ts.total_supply_cost,
    ot.total_order_value,
    ot.total_order_value - ts.total_supply_cost AS profit_margin
FROM 
    ranked_suppliers ts
JOIN 
    top_nations ns ON ts.s_nationkey = ns.n_nationkey
JOIN 
    order_totals ot ON ot.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey LIMIT 1)
WHERE 
    ts.cost_rank <= 3
ORDER BY 
    ns.n_name, ts.total_supply_cost DESC;
