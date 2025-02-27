WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-11-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRegions AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        SUM(RO.total_revenue) AS region_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedOrders RO ON ps.ps_partkey IN 
            (SELECT l.l_partkey 
             FROM lineitem l 
             WHERE l.l_orderkey = RO.o_orderkey)
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    tr.r_name, 
    tr.region_revenue, 
    ROW_NUMBER() OVER (ORDER BY tr.region_revenue DESC) AS rank
FROM 
    TopRegions tr
WHERE 
    tr.region_revenue > 0
ORDER BY 
    tr.region_revenue DESC
LIMIT 10;
