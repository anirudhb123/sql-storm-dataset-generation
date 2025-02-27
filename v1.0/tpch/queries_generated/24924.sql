WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND l.l_shipdate <= CURRENT_DATE
    GROUP BY 
        o.o_orderkey, o.o_custkey
), CrossJoinRegions AS (
    SELECT 
        n.n_nationkey,
        SUM(CASE WHEN r.r_name IS NOT NULL THEN 1 ELSE 0 END) AS region_count
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    COALESCE(o.total_revenue, 0) AS total_revenue,
    COALESCE(r.region_count, 0) AS region_count,
    s.s_name,
    COUNT(DISTINCT l.l_orderkey) AS unique_orders,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE NULL END) AS max_return_price
FROM 
    customer c
LEFT JOIN 
    FilteredOrders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    RankedSuppliers s ON s.rn = 1
LEFT JOIN 
    CrossJoinRegions r ON c.c_nationkey = r.n_nationkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    c.c_custkey, c.c_name, c.c_acctbal, o.total_revenue, r.region_count, s.s_name
HAVING 
    SUM(l.l_quantity) > (SELECT AVG(ps.ps_availqty) FROM partsupp ps) 
    OR COUNT(s.s_suppkey) > 10
ORDER BY 
    total_revenue DESC, c.c_acctbal ASC 
LIMIT 100 OFFSET 50;
