
WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_retailprice AS retail_price,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' provides ', p.p_name, ' at a retail price of $', 
               ROUND(p.p_retailprice, 2), ' with an available quantity of ', 
               CAST(ps.ps_availqty AS CHAR), '.') AS detailed_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregatedInfo AS (
    SELECT 
        supplier_name,
        COUNT(part_name) AS total_parts,
        SUM(available_quantity) AS total_available_quantity,
        AVG(retail_price) AS average_retail_price,
        SUM(supply_cost) AS total_supply_cost
    FROM 
        SupplierParts
    GROUP BY 
        supplier_name
)
SELECT 
    supplier_name,
    total_parts,
    total_available_quantity,
    average_retail_price,
    total_supply_cost,
    CONCAT('Supplier: ', supplier_name, ' has ', total_parts, 
           ' parts available, with a total availability of ', 
           total_available_quantity, '. The average retail price is $', 
           ROUND(average_retail_price, 2), ' and the total supply cost is $', 
           ROUND(total_supply_cost, 2), '.') AS summary
FROM 
    AggregatedInfo
ORDER BY 
    total_parts DESC, average_retail_price DESC;
