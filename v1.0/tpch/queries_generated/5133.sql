WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        SUM(so.total_revenue) AS region_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedOrders so ON ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_orderdate >= DATE '2023-01-01')
    GROUP BY 
        r.r_regionkey
)
SELECT 
    r.r_name,
    tr.region_revenue,
    (SELECT COUNT(DISTINCT c.c_custkey) FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)) AS customer_count
FROM 
    region r
JOIN 
    TopRegions tr ON r.r_regionkey = tr.r_regionkey
ORDER BY 
    tr.region_revenue DESC
LIMIT 10;
