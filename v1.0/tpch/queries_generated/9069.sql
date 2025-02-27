WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        SUM(CASE WHEN ps.ps_availqty < 100 THEN ps.ps_availqty ELSE 0 END) AS low_avail_quantity,
        SUM(ps.ps_supplycost) AS total_costs,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT s.*
    FROM SupplierStats s
    WHERE s.rank <= 5
)
SELECT 
    t.s_name,
    t.nation_name,
    t.parts_count,
    t.total_supply_cost,
    t.low_avail_quantity,
    ROUND((t.total_supply_cost / NULLIF(t.parts_count, 0)), 2) AS avg_supply_cost_per_part
FROM TopSuppliers t
ORDER BY t.total_supply_cost DESC;
