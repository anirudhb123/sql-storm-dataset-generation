
WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_name, p.p_brand, COUNT(ps.ps_partkey) AS part_count,
           STRING_AGG(DISTINCT p.p_type, ', ') AS types,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_brand, p.p_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(supply_part_count) AS total_parts
    FROM (
        SELECT s.s_suppkey, s.s_name, COUNT(*) AS supply_part_count
        FROM supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        GROUP BY s.s_suppkey, s.s_name
    ) AS s
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_parts DESC
    LIMIT 10
)
SELECT ts.s_suppkey, ts.s_name, sp.part_count, sp.types, sp.avg_supply_cost
FROM TopSuppliers ts
JOIN SupplierParts sp ON ts.s_suppkey = sp.s_suppkey
ORDER BY sp.avg_supply_cost DESC;
