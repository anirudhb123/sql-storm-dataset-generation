WITH StringAggregates AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        STRING_AGG(DISTINCT CONCAT(p.p_name, ': ', p.p_comment), ', ') AS part_details,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        MAX(s.s_acctbal) AS max_account_balance,
        MIN(length(s.s_comment)) AS min_comment_length
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredSuppliers AS (
    SELECT 
        *,
        CASE 
            WHEN part_count > 10 THEN 'High Supplier'
            WHEN part_count BETWEEN 5 AND 10 THEN 'Medium Supplier'
            ELSE 'Low Supplier'
        END AS supplier_category
    FROM 
        StringAggregates
)
SELECT 
    s.supp_name,
    s.part_details,
    s.total_supply_cost,
    s.max_account_balance,
    s.supplier_category
FROM 
    FilteredSuppliers s
WHERE 
    s.max_account_balance > 10000 
    AND s.supplier_category = 'High Supplier'
ORDER BY 
    s.total_supply_cost DESC;
