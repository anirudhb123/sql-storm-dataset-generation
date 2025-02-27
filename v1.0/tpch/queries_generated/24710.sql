WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
HighVolumeLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        l.l_orderkey
    HAVING 
        COUNT(l.l_linenumber) > 5
),
CombinedData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty,
        MAX(CASE WHEN ps.ps_supplycost IS NOT NULL THEN ps.ps_supplycost ELSE 0 END) AS max_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    c.c_mktsegment,
    SUM(cd.total_avail_qty) AS total_available,
    AVG(cd.max_supply_cost) AS avg_supply_cost,
    COUNT(DISTINCT lv.l_orderkey) AS high_volume_order_count,
    STRING_AGG(DISTINCT s.s_name) AS supplier_names
FROM 
    RankedSuppliers s
JOIN 
    nation n ON s.s_suppkey = n.n_nationkey
JOIN 
    CombinedData cd ON n.n_nationkey IN (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_mktsegment = 'BUILDING')
LEFT JOIN 
    HighVolumeLineItems lv ON lv.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F' AND o.o_totalprice > 5000)
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name,
    c.c_mktsegment
HAVING 
    avg_supply_cost > (SELECT AVG(max_supply_cost) FROM CombinedData) 
    OR EXISTS (SELECT 1 FROM HighVolumeLineItems hv WHERE hv.line_count > 10)
ORDER BY 
    total_available DESC, avg_supply_cost DESC;
