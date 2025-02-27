WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        SUBSTRING(s.s_comment, 1, 30) AS supplier_comment_preview,
        CONCAT(p.p_name, ' - ', s.s_name) AS combined_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
HighValueSuppliers AS (
    SELECT 
        supplier_name, 
        SUM(available_quantity * supply_cost) AS total_supply_value
    FROM 
        SupplierPartDetails
    GROUP BY 
        supplier_name
    HAVING 
        SUM(available_quantity * supply_cost) > 10000
) 
SELECT 
    DISTINCT 
    H.supplier_name, 
    H.total_supply_value,
    DENSE_RANK() OVER (ORDER BY H.total_supply_value DESC) AS supply_rank,
    CONCAT('Total Supply Value: $', FORMAT(H.total_supply_value, 2)) AS supply_value_message,
    (SELECT COUNT(*) FROM SupplierPartDetails D WHERE D.supplier_name = H.supplier_name) AS part_count
FROM 
    HighValueSuppliers H
ORDER BY 
    H.total_supply_value DESC;
