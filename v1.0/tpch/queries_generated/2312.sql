WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) as rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '2020-01-01' AND o.o_orderdate < '2021-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    coalesce(ro.o_orderkey, li.l_orderkey) AS order_key,
    coalesce(ro.o_orderdate, 'N/A') AS order_date,
    COALESCE(SUM(li.total_revenue), 0) AS total_revenue,
    COALESCE(s.total_available, 0) AS total_available,
    COALESCE(s.avg_supply_cost, 0.00) AS average_supply_cost,
    RO.rank
FROM 
    RankedOrders ro
FULL OUTER JOIN 
    LineItemAggregates li ON ro.o_orderkey = li.l_orderkey
LEFT JOIN 
    SupplierStats s ON s.total_available > 0
WHERE 
    s.part_count > 10 OR s.part_count IS NULL
GROUP BY 
    ro.o_orderkey, li.l_orderkey, ro.o_orderdate, s.total_available, s.avg_supply_cost, ro.rank
ORDER BY 
    total_revenue DESC
LIMIT 100;
