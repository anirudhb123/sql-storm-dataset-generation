WITH RegionalSuppliers AS (
    SELECT
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(s.s_acctbal) AS avg_account_balance,
        STRING_AGG(DISTINCT s.s_name, '; ') AS supplier_names
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        r.r_name
)
SELECT 
    region_name,
    supplier_count,
    total_available_quantity,
    avg_account_balance,
    CONCAT('Suppliers: ', supplier_names) AS supplier_list
FROM 
    RegionalSuppliers
WHERE 
    avg_account_balance > (
        SELECT AVG(s_acctbal) FROM supplier
    )
ORDER BY 
    total_available_quantity DESC;
