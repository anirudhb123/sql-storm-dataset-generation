WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        CONCAT(p.p_name, ' - ', p.p_brand, ' (', p.p_mfgr, ')') AS full_description,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nations
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        COUNT(l.l_linenumber) AS lineitem_count,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') -- Only consider orders that have been placed or fulfilled
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    sa.full_description,
    sa.suppliers,
    sa.nations,
    os.lineitem_count,
    os.total_revenue
FROM 
    StringAggregation sa
LEFT JOIN 
    OrderSummary os ON sa.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MIN(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = ps.ps_partkey))
WHERE 
    sa.suppliers IS NOT NULL
ORDER BY 
    os.total_revenue DESC, sa.full_description;
