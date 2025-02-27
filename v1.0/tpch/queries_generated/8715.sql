WITH nation_summary AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey
),
final_summary AS (
    SELECT 
        ns.nation_name,
        ns.supplier_count,
        ns.total_available_quantity,
        ns.total_supply_cost,
        os.total_order_value,
        os.total_line_items
    FROM 
        nation_summary ns
    LEFT JOIN 
        order_summary os ON ns.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps)) LIMIT 1)
)
SELECT 
    nation_name,
    supplier_count,
    total_available_quantity,
    total_supply_cost,
    COALESCE(SUM(total_order_value), 0) AS total_order_value,
    COALESCE(SUM(total_line_items), 0) AS total_line_items
FROM 
    final_summary
GROUP BY 
    nation_name, supplier_count, total_available_quantity, total_supply_cost
ORDER BY 
    supplier_count DESC, total_order_value DESC
LIMIT 10;
