WITH aggregated_supplier_info AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        STRING_AGG(DISTINCT p.p_name, ', ') AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),

nation_part_analysis AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT a.s_suppkey) AS distinct_suppliers,
        SUM(a.total_supply_cost) AS total_supply_cost,
        STRING_AGG(DISTINCT a.parts_supplied, '; ') AS all_parts_supplied
    FROM nation n
    JOIN aggregated_supplier_info a ON n.n_nationkey = a.s_nationkey
    GROUP BY n.n_name
)

SELECT 
    npa.nation_name,
    npa.distinct_suppliers,
    npa.total_supply_cost,
    npa.all_parts_supplied
FROM nation_part_analysis npa
WHERE npa.total_supply_cost > (SELECT AVG(total_supply_cost) FROM nation_part_analysis)
ORDER BY npa.total_supply_cost DESC;
