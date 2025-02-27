WITH Part_Supplier_Info AS (
    SELECT 
        p.p_name,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
Filtered_Suppliers AS (
    SELECT 
        p_name,
        s_name,
        ps_availqty,
        ps_supplycost
    FROM Part_Supplier_Info
    WHERE rank <= 3
),
Aggregated_Info AS (
    SELECT 
        p_name,
        COUNT(s_name) AS supplier_count,
        SUM(ps_supplycost) AS total_supply_cost,
        AVG(ps_availqty) AS avg_avail_quantity
    FROM Filtered_Suppliers
    GROUP BY p_name
)
SELECT 
    p_name,
    supplier_count,
    total_supply_cost,
    avg_avail_quantity,
    CONCAT('Supplier Count: ', supplier_count, ', Total Cost: $', FORMAT(total_supply_cost, 2), ', Avg Availability: ', FORMAT(avg_avail_quantity, 2)) AS summary
FROM Aggregated_Info
ORDER BY supplier_count DESC, total_supply_cost DESC;
