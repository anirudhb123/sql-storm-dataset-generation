WITH RankedOrders AS (
    SELECT 
        o.orderkey,
        o.totalprice,
        o.orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.mktsegment ORDER BY o.totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.custkey = c.custkey
    WHERE 
        o.orderdate >= '2023-01-01'
),
SupplierStats AS (
    SELECT 
        s.suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.suppkey = ps.ps_suppkey
    GROUP BY 
        s.suppkey
),
LineItemAnalytics AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_tax) AS avg_tax_rate,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.orderkey,
    o.totalprice,
    COALESCE(l.total_revenue, 0) AS total_revenue,
    COALESCE(s.total_avail_qty, 0) AS total_avail_qty,
    s.avg_supply_cost,
    RANK() OVER (ORDER BY o.totalprice DESC) AS price_rank
FROM 
    RankedOrders o
LEFT JOIN 
    LineItemAnalytics l ON o.orderkey = l.l_orderkey
LEFT JOIN 
    SupplierStats s ON s.suppkey = (
        SELECT ps.suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_retailprice > 100 
        ORDER BY ps.ps_supplycost ASC 
        LIMIT 1
    )
WHERE 
    o.rn = 1
ORDER BY 
    o.orderdate DESC;
