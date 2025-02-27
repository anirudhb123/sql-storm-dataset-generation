
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'Unknown Price'
            ELSE CONCAT(p.p_name, ' - $', CAST(p.p_retailprice AS CHAR))
        END AS price_description
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_comment LIKE '%small%')
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = o.o_orderkey AND l.l_returnflag = 'R') AS return_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING' AND o.o_orderstatus = 'F'
),
ComplexAnalysis AS (
    SELECT 
        co.c_custkey,
        co.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        CustomerOrders co
    JOIN 
        lineitem l ON l.l_orderkey = co.o_orderkey
    GROUP BY 
        co.c_custkey, co.o_orderkey
)
SELECT 
    f.p_partkey,
    f.price_description,
    r.s_name AS top_supplier,
    ca.total_value,
    ca.unique_parts,
    (CASE 
        WHEN ca.total_value > 10000 THEN 'High Value'
        WHEN ca.total_value IS NULL THEN 'No Value'
        ELSE 'Low to Medium Value'
     END) AS value_category
FROM 
    FilteredParts f
LEFT JOIN 
    RankedSuppliers r ON r.rn = 1
LEFT JOIN 
    ComplexAnalysis ca ON EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_partkey = f.p_partkey 
        AND l.l_orderkey IN (
            SELECT o.o_orderkey 
            FROM orders o 
            WHERE o.o_custkey IN (
                SELECT c.c_custkey 
                FROM customer c 
                WHERE c.c_mktsegment = 'BUILDING'
            )
        )
    )
ORDER BY 
    f.p_partkey ASC, 
    ca.total_value DESC NULLS LAST;
