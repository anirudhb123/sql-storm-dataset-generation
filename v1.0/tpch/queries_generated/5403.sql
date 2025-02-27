WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        OYear.year,
        RANK() OVER (PARTITION BY OYear.year ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    CROSS JOIN (
        SELECT DISTINCT EXTRACT(YEAR FROM o_orderdate) AS year 
        FROM orders
    ) OYear
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(distinct ro.o_orderkey) AS total_orders,
        SUM(ro.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ro.o_orderkey)
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        total_orders > 5 AND total_spent > 10000
),
SupplierPartCount AS (
    SELECT 
        ps.ps_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        part_count > 10
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_regionkey, r.r_name
    ORDER BY 
        total_revenue DESC
    LIMIT 5
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    r.r_name AS region_name,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    SUM(ro.o_totalprice) AS total_spent,
    COUNT(DISTINCT sp.ps_suppkey) AS supplier_count,
    SUM(sp.part_count) AS total_parts
FROM 
    CustomerOrders c
LEFT JOIN 
    SupplierPartCount sp ON TRUE
JOIN 
    TopRegions r ON TRUE
JOIN 
    RankedOrders ro ON ro.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = ro.o_orderkey)
GROUP BY 
    customer_name, region_name
HAVING 
    order_count > 3
ORDER BY 
    total_spent DESC;
