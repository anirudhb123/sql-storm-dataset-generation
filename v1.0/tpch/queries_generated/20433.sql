WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipmode IN ('AIR', 'GROUND') 
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(ld.total_cost, 0) AS supplier_total_cost,
    COALESCE(ra.o_totalprice, 0) AS highest_order_price,
    la.net_revenue,
    la.line_count,
    CASE 
        WHEN la.line_count > 10 THEN 'High Volume'
        WHEN la.line_count BETWEEN 5 AND 10 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM 
    part p
LEFT JOIN 
    SupplierDetails ld ON ld.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
LEFT JOIN 
    RankedOrders ra ON ra.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
    ) 
LEFT JOIN 
    LineItemAggregates la ON la.l_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
    )
WHERE 
    p.p_size BETWEEN 1 AND 100
    AND (p.p_retailprice IS NOT NULL OR p.p_comment IS NOT NULL)
ORDER BY 
    p.p_retailprice DESC, 
    volume_category ASC;

