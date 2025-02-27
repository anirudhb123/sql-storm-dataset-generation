WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        p.p_partkey, p.p_name
),
TopParts AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY supplier_count DESC) AS rank
    FROM
        RankedParts
)
SELECT
    tp.p_partkey,
    tp.p_name,
    tp.supplier_count,
    tp.suppliers,
    CASE
        WHEN tp.supplier_count > 5 THEN 'High Supply'
        WHEN tp.supplier_count BETWEEN 3 AND 5 THEN 'Medium Supply'
        ELSE 'Low Supply'
    END AS supply_status
FROM
    TopParts tp
WHERE
    tp.rank <= 10
ORDER BY
    tp.supplier_count DESC;
