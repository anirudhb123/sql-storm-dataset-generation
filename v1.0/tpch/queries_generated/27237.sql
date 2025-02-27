WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        REPLACE(p.p_comment, 'dummy', 'replaced') AS modified_comment
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50.00
),
StringAggregation AS (
    SELECT 
        STRING_AGG(DISTINCT l.l_shipinstruct, ', ') AS ship_instructions,
        STRING_AGG(DISTINCT c.c_name, ' | ') AS customer_names
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        l.l_discount > 0.05
)
SELECT 
    rs.s_name,
    rs.s_address,
    rs.s_phone,
    rs.s_acctbal,
    p.p_name,
    p.modified_comment,
    coc.order_count,
    sa.ship_instructions,
    sa.customer_names
FROM 
    RankedSuppliers rs
JOIN 
    FilteredParts p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey)
JOIN 
    CustomerOrderCount coc ON coc.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = rs.s_suppkey))
CROSS JOIN 
    StringAggregation sa
WHERE 
    rs.rn <= 5
ORDER BY 
    rs.s_acctbal DESC, coc.order_count DESC;
