WITH RECURSIVE RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS rank
    FROM 
        orders
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS returns_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_custkey,
    r.o_totalprice,
    COALESCE(fs.total_line_price, 0) AS total_line_items,
    ss.total_parts,
    ss.avg_supply_cost
FROM 
    RankedOrders r 
LEFT JOIN 
    FilteredLineItems fs ON r.o_orderkey = fs.l_orderkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = (
        SELECT 
            ps.ps_suppkey
        FROM 
            partsupp ps
        JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE 
            l.l_orderkey = r.o_orderkey
        LIMIT 1
    )
WHERE 
    r.rank = 1
ORDER BY 
    r.o_totalprice DESC
LIMIT 100;
