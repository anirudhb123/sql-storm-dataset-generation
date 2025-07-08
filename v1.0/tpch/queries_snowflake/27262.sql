
WITH RankedSuppliers AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_acctbal AS account_balance,
        p.p_name AS part_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        supplier_name,
        account_balance,
        part_name
    FROM 
        RankedSuppliers
    WHERE 
        rank <= 3
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        COUNT(DISTINCT ts.supplier_name) AS supplier_count,
        LISTAGG(DISTINCT ts.supplier_name, ', ') WITHIN GROUP (ORDER BY ts.supplier_name) AS suppliers_list
    FROM 
        part p
    LEFT JOIN 
        TopSuppliers ts ON p.p_name = ts.part_name
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    pd.p_size,
    pd.supplier_count,
    pd.suppliers_list,
    CASE 
        WHEN pd.supplier_count > 0 THEN CONCAT('Available from ', pd.supplier_count, ' suppliers: ', pd.suppliers_list)
        ELSE 'No suppliers available'
    END AS supplier_info
FROM 
    PartDetails pd
WHERE 
    pd.supplier_count > 0 
ORDER BY 
    pd.supplier_count DESC, pd.p_size ASC;
