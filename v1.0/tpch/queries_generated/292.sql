WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        s.s_acctbal
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        p.p_type
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20 AND 
        p.p_retailprice > 100.00
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_name,
    p.p_type,
    s.s_name,
    n.n_name,
    os.line_count,
    os.total_sales,
    os.avg_quantity
FROM 
    FilteredParts p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank <= 5
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    OrderStats os ON os.o_orderkey IN (
        SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey
    )
WHERE 
    n.n_name IS NOT NULL
ORDER BY 
    total_sales DESC, 
    avg_quantity ASC
LIMIT 10;
