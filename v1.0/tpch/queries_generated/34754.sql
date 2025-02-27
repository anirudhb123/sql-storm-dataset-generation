WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS hierarchy_level
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
  
    UNION ALL

    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.hierarchy_level + 1
    FROM 
        OrderHierarchy oh
    JOIN 
        orders o ON oh.o_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
),
AggregatedData AS (
    SELECT 
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT o.o_orderkey) AS num_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        c.c_nationkey
)
SELECT 
    r.r_name,
    COALESCE(ad.revenue, 0) AS total_revenue,
    ad.num_orders,
    ad.rank
FROM 
    region r
LEFT JOIN 
    AggregatedData ad ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = ad.c_nationkey)
WHERE 
    r.r_name IS NOT NULL
OR 
    r.r_comment IS NOT NULL
ORDER BY 
    total_revenue DESC, r.r_name;
