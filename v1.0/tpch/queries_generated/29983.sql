WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
),
AggregatedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    rnp.p_name,
    rnp.p_mfgr,
    rnp.p_brand,
    rnp.p_retailprice,
    fs.s_name,
    fs.s_address,
    ao.total_line_items,
    ao.total_revenue
FROM 
    RankedParts rnp
JOIN 
    FilteredSuppliers fs ON rnp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = fs.s_suppkey)
JOIN 
    AggregatedOrders ao ON rnp.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ao.o_orderkey)
WHERE 
    rnp.rnk <= 5
ORDER BY 
    rnp.p_retailprice DESC, ao.total_revenue DESC;
