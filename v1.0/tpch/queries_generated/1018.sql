WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 100
),
CustomerTotal AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS customer_total
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FinalReport AS (
    SELECT 
        n.n_name AS nation,
        r.r_name AS region,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(COALESCE(o.o_totalprice, 0)) AS total_order_value,
        AVG(COALESCE(o.o_totalprice, 0)) AS avg_order_value
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    f.nation, 
    f.region, 
    f.total_customers, 
    f.total_order_value, 
    CASE 
        WHEN f.total_order_value > 0 THEN ROUND(f.total_order_value / NULLIF(f.total_customers, 0), 2)
        ELSE 0 
    END AS avg_order_value,
    ss.s_name,
    ss.total_available,
    rs.total_revenue
FROM 
    FinalReport f
LEFT JOIN 
    SupplierStats ss ON ss.total_available > 150
LEFT JOIN 
    RankedOrders rs ON f.total_order_value BETWEEN 1000 AND 50000
WHERE 
    f.total_customers IS NOT NULL
ORDER BY 
    f.region, f.nation;
