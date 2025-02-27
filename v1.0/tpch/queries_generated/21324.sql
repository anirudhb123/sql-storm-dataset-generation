WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        CASE 
            WHEN p.p_size BETWEEN 1 AND 5 THEN 'Small'
            WHEN p.p_size BETWEEN 6 AND 15 THEN 'Medium'
            WHEN p.p_size > 15 THEN 'Large'
            ELSE 'Undefined'
        END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL AND p.p_retailprice > 0
),
OrderSummaries AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(r.rank, 0) AS supplier_rank,
    fs.total_value,
    fs.item_count,
    CASE 
        WHEN fs.item_count > 0 THEN 'Has orders'
        ELSE 'No orders'
    END AS order_status,
    CONCAT('Part ', p.p_name, ' is categorized as ', p.size_category) AS part_description
FROM 
    FilteredParts p
LEFT JOIN 
    RankedSuppliers r ON p.p_partkey IN (
        SELECT 
            ps.ps_partkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_availqty > 0
        INTERSECT 
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_shipdate >= '2023-01-01'
    )
LEFT JOIN 
    OrderSummaries fs ON fs.o_orderkey IN (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderstatus = 'F'
            AND o.o_orderdate < CURRENT_DATE - INTERVAL '30 days'
    )
WHERE 
    (p.p_size IS NOT NULL AND p.p_size > 10)
    OR (p.p_name LIKE '%part%' AND p.p_retailprice < 50.00)
ORDER BY 
    supplier_rank DESC NULLS LAST, 
    p.p_retailprice ASC;
