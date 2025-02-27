WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
CustomerExports AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PotentialSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 1000
),
RevenueDetails AS (
    SELECT 
        r.r_name,
        COALESCE(SUM(ro.total_revenue), 0) AS region_revenue
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN 
        RankedOrders ro ON o.o_orderkey = ro.o_orderkey
    GROUP BY 
        r.r_name
)
SELECT 
    ce.c_name AS customer_name,
    ce.total_quantity,
    rd.region_revenue,
    CASE 
        WHEN rd.region_revenue > 100000 THEN 'High Revenue'
        WHEN rd.region_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    ps.s_name AS supplier_name,
    ps.total_available_qty
FROM 
    CustomerExports ce
JOIN 
    RevenueDetails rd ON ce.total_orders > 5
JOIN 
    PotentialSuppliers ps ON ce.total_quantity > 100
WHERE 
    ce.total_quantity IS NOT NULL AND ps.total_available_qty IS NOT NULL
ORDER BY 
    ce.total_quantity DESC, rd.region_revenue DESC;
