
WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        CONCAT('Part: ', p.p_name, ' | Brand: ', p.p_brand, ' | Type: ', p.p_type, ' | Comment: ', p.p_comment) AS part_details,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
        STRING_AGG(DISTINCT n.n_name, ', ') AS supplier_nations,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_comment
),
FinalResults AS (
    SELECT 
        p.p_partkey,
        p.part_details,
        p.total_returned_quantity,
        p.supplier_nations,
        p.unique_suppliers,
        RANK() OVER (ORDER BY p.total_returned_quantity DESC) AS rank_by_returned_quantity
    FROM StringAggregation p
)
SELECT 
    f.p_partkey,
    f.part_details,
    f.total_returned_quantity,
    f.supplier_nations,
    f.unique_suppliers,
    f.rank_by_returned_quantity
FROM FinalResults f
WHERE f.rank_by_returned_quantity <= 10
ORDER BY f.rank_by_returned_quantity;
