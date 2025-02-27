WITH RECURSIVE PriceChanges AS (
    SELECT 
        ps_partkey,
        ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rn
    FROM 
        partsupp
    WHERE 
        ps_supplycost > 0
),
RecentOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM 
        orders
    JOIN 
        lineitem ON orders.o_orderkey = lineitem.l_orderkey
    WHERE 
        o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
    GROUP BY 
        o_orderkey, o_custkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        MAX(s.s_acctbal) AS max_acctbal,
        COUNT(*) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        COUNT(*) > 10
),
RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.total_revenue) AS customer_revenue,
        RANK() OVER (ORDER BY SUM(ro.total_revenue) DESC) AS revenue_rank
    FROM 
        customer c
    LEFT JOIN 
        RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    COALESCE(pc.ps_supplycost, 0) AS highest_supplycost,
    SUM(cd.total_parts) AS total_parts_supplied,
    rc.customer_revenue,
    rc.revenue_rank,
    r.r_name AS supplier_region,
    CASE 
        WHEN rc.revenue_rank <= 10 THEN 'Top Customer'
        WHEN rc.revenue_rank <= 50 THEN 'Medium Customer'
        ELSE 'Low Customer'
    END AS customer_category
FROM 
    part p
LEFT JOIN 
    PriceChanges pc ON p.p_partkey = pc.ps_partkey AND pc.rn = 1
LEFT JOIN 
    SupplierDetails sd ON p.p_partkey = sd.s_suppkey
LEFT JOIN 
    RankedCustomers rc ON sd.s_suppkey = rc.c_custkey
JOIN 
    nation n ON sd.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    p.p_name, pc.ps_supplycost, rc.customer_revenue, rc.revenue_rank, r.r_name
HAVING 
    SUM(cd.total_parts) > 100
ORDER BY 
    highest_supplycost DESC, customer_revenue DESC;
