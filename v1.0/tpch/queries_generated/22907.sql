WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank,
        NULLIF(s.s_comment, '') AS supplier_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(p.p_retailprice) AS avg_retailprice
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 100
),
OrderValues AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    r.s_suppkey,
    r.s_name,
    r.s_acctbal,
    fp.p_partkey,
    fp.p_name,
    fp.total_availqty,
    ov.order_value,
    ov.distinct_parts,
    COALESCE(r.supplier_comment, 'No comment') AS supplier_info,
    CASE 
        WHEN r.supplier_rank = 1 THEN 'Top Supplier'
        WHEN r.supplier_rank BETWEEN 2 AND 5 THEN 'Mid-tier Supplier'
        ELSE 'Other Supplier'
    END AS supplier_category
FROM 
    RankedSuppliers r
JOIN 
    FilteredParts fp ON r.s_suppkey = (
        SELECT
            ps.ps_suppkey
        FROM 
            partsupp ps
        WHERE 
            ps.ps_partkey = fp.p_partkey
        ORDER BY 
            ps.ps_supplycost ASC
        LIMIT 1
    )
LEFT JOIN 
    OrderValues ov ON ov.o_orderkey = (SELECT 
                                            o.o_orderkey 
                                        FROM 
                                            orders o 
                                        JOIN 
                                            lineitem l ON o.o_orderkey = l.l_orderkey 
                                        WHERE 
                                            l.l_partkey = fp.p_partkey 
                                        ORDER BY 
                                            o.o_orderdate DESC 
                                        LIMIT 1 
                                       )
WHERE 
    r.s_acctbal IS NOT NULL
    AND fp.total_availqty IS NOT NULL
    AND (ov.order_value IS NULL OR ov.distinct_parts > 2)
ORDER BY 
    r.s_name, fp.p_name;
