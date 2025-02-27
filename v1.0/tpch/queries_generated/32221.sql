WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey,
        0 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey,
        oh.level + 1
    FROM 
        orders o
    INNER JOIN 
        OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE 
        oh.level < 5
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
),
AggregatedLineitems AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FinalResults AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        r.r_name,
        COALESCE(c.total_spent, 0) AS customer_spent,
        s.total_availqty,
        s.avg_supplycost,
        a.total_revenue,
        a.order_count,
        CASE 
            WHEN COALESCE(a.total_revenue, 0) > 10000 THEN 'High Revenue'
            WHEN COALESCE(a.total_revenue, 0) BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
            ELSE 'Low Revenue'
        END AS revenue_category
    FROM 
        part p
    LEFT JOIN 
        SupplierPartStats s ON p.p_partkey = s.ps_partkey
    LEFT JOIN 
        region r ON s.s_nationkey = r.r_regionkey 
    LEFT JOIN 
        CustomerRevenue c ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = s.s_nationkey))
    LEFT JOIN 
        AggregatedLineitems a ON p.p_partkey = a.l_partkey
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.r_name,
    f.customer_spent,
    f.total_availqty,
    f.avg_supplycost,
    f.total_revenue,
    f.order_count,
    f.revenue_category
FROM 
    FinalResults f
WHERE 
    f.total_availqty IS NOT NULL
ORDER BY 
    f.total_revenue DESC, f.customer_spent ASC;
