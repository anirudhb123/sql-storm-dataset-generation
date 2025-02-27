WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
),
SuppliersWithHighSupplyCost AS (
    SELECT 
        ps.ps_suppkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > (
            SELECT 
                AVG(p2.p_retailprice) 
            FROM 
                part p2
        )
    GROUP BY 
        ps.ps_suppkey
),
RecentOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        s.s_suppkey,
        l.l_quantity,
        l.l_discount,
        l.l_returnflag,
        l.l_shipdate,
        COALESCE(NULLIF(l.l_discount, 0), 0.01) AS adjusted_discount
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    LEFT JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    WHERE 
        ro.rn <= 5
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT r.o_orderkey) AS order_count,
    SUM(r.l_extendedprice * (1 - r.adjusted_discount)) AS total_revenue,
    AVG(h.avg_supplycost) AS avg_supplier_cost
FROM 
    RecentOrders r
JOIN 
    nation n ON n.n_nationkey = r.c_nationkey
JOIN 
    SuppliersWithHighSupplyCost h ON r.s_suppkey = h.ps_suppkey
WHERE 
    r.l_returnflag = 'R'
    AND r.l_shipdate > CURRENT_DATE - INTERVAL '30 days'
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10
UNION ALL
SELECT 
    'Total' AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - COALESCE(NULLIF(l.l_discount, 0), 0.01))) AS total_revenue,
    0 AS avg_supplier_cost
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate < CURRENT_DATE - INTERVAL '1 year'
    AND l.l_returnflag <> 'R';
