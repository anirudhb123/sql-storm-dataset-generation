
WITH String_Aggregation AS (
    SELECT 
        p.p_partkey,
        STRING_AGG(DISTINCT p.p_name, '; ') AS aggregated_names,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        p.p_partkey
),
String_Filtered AS (
    SELECT 
        p_partkey,
        aggregated_names,
        supplier_names,
        unique_customers
    FROM 
        String_Aggregation
    WHERE 
        CHAR_LENGTH(aggregated_names) < 150
)
SELECT 
    sf.p_partkey,
    sf.aggregated_names,
    sf.supplier_names,
    sf.unique_customers,
    REPLACE(sf.aggregated_names, '; ', ', ') AS modified_names,
    CONCAT('Total Customers: ', sf.unique_customers) AS customer_info
FROM 
    String_Filtered sf
ORDER BY 
    sf.unique_customers DESC
LIMIT 10;
