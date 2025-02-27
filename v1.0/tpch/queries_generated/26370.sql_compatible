
WITH StringAggregates AS (
    SELECT 
        s.s_suppkey AS suppkey,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        STRING_AGG(DISTINCT p.p_name, '; ') AS part_names,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
        MAX(s.s_acctbal) AS max_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
FilteredSuppliers AS (
    SELECT 
        s.suppkey,
        s.part_count,
        s.total_available_quantity,
        s.part_names,
        s.supplier_names,
        s.max_account_balance
    FROM 
        StringAggregates s
    WHERE 
        s.max_account_balance > 5000
)
SELECT 
    fs.suppkey,
    fs.part_count,
    fs.total_available_quantity,
    fs.part_names,
    fs.supplier_names,
    fs.max_account_balance,
    CONCAT('Supplier ', fs.supplier_names, ' has ', fs.part_count, ' types of parts available with a total quantity of ', fs.total_available_quantity) AS report_summary
FROM 
    FilteredSuppliers fs
ORDER BY 
    fs.max_account_balance DESC;
