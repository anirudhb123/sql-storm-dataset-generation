
WITH StringAggregation AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' in ', p.p_container, ' containers.') AS supply_description,
        STRING_AGG(CONCAT(c.c_name, ' from ', n.n_name), '; ') AS customers_served
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY p.p_name, s.s_name, p.p_container
),
FinalOutput AS (
    SELECT 
        part_name,
        supplier_name,
        supply_description,
        customers_served,
        LENGTH(supply_description) AS description_length,
        UPPER(part_name) AS part_name_upper,
        LEFT(customers_served, 50) AS trimmed_customers_served
    FROM StringAggregation
)
SELECT 
    part_name,
    supplier_name,
    supply_description,
    customers_served,
    description_length,
    part_name_upper,
    trimmed_customers_served
FROM FinalOutput
WHERE description_length > 100
ORDER BY description_length DESC;
