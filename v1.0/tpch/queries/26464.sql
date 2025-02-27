
WITH StringAggregation AS (
    SELECT 
        CONCAT('Region ', r_name, ' - Comment: ', r_comment) AS aggregated_string
    FROM 
        region
), 
SupplierNames AS (
    SELECT 
        CONCAT('Supplier Name: ', s_name, ' (', s_phone, ')') AS supplier_info
    FROM 
        supplier
), 
CustomerDetails AS (
    SELECT 
        CONCAT(c_name, ' from ', c_address, ', Segment: ', c_mktsegment) AS customer_detail
    FROM 
        customer
), 
PartDetails AS (
    SELECT 
        CONCAT('Part: ', p_name, ', Brand: ', p_brand, ', Type: ', p_type) AS part_info
    FROM 
        part
),
Combination AS (
    SELECT 
        sa.aggregated_string,
        sup.supplier_info,
        cust.customer_detail,
        part.part_info
    FROM 
        StringAggregation sa
    CROSS JOIN 
        SupplierNames sup 
    CROSS JOIN 
        CustomerDetails cust 
    CROSS JOIN 
        PartDetails part 
    LIMIT 10
)
SELECT 
    STRING_AGG(CONCAT(aggregated_string, ' | ', supplier_info, ' | ', customer_detail, ' | ', part_info), '; ') AS benchmark_result
FROM 
    Combination;
