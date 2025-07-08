
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.part_count,
        s.total_supply_value,
        s.part_names,
        DENSE_RANK() OVER (ORDER BY s.total_supply_value DESC) AS rank
    FROM SupplierStats s
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.part_count,
    t.total_supply_value,
    t.part_names
FROM TopSuppliers t
WHERE t.rank <= 10
ORDER BY t.total_supply_value DESC;
