
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
), SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), ItemSales AS (
    SELECT 
        li.l_partkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_orderkey) AS order_count
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate >= '1997-01-01' AND li.l_shipdate < '1998-01-01'
    GROUP BY 
        li.l_partkey
)
SELECT 
    p.p_name,
    r.r_name,
    COALESCE(ss.total_available, 0) AS total_available,
    COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(iss.total_revenue, 0) AS total_revenue,
    COALESCE(iss.order_count, 0) AS order_count,
    CASE 
        WHEN ios.price_rank IS NOT NULL THEN 'High Value Market Segment' 
        ELSE 'Other Market Segment' 
    END AS market_segment_category
FROM 
    part p
LEFT JOIN 
    SupplierStats ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN 
    ItemSales iss ON p.p_partkey = iss.l_partkey
LEFT JOIN 
    RankedOrders ios ON ios.o_orderkey IN (
        SELECT o_orderkey 
        FROM orders o 
        WHERE o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
        AND o.o_totalprice > 1000
    )
JOIN 
    nation n ON p.p_mfgr = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 10
ORDER BY 
    total_revenue DESC, total_available DESC;
