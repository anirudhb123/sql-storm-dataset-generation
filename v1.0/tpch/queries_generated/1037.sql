WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM supplier s
), HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
), RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_totalprice,
        DATE_PART('year', o.o_orderdate) AS order_year
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
), LineitemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(*) AS line_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT 
    r.r_name AS Region,
    n.n_name AS Nation,
    s.s_name AS SupplierName,
    c.c_name AS CustomerName,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    COALESCE(SUM(ld.revenue), 0) AS TotalRevenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers s ON n.n_nationkey = s.s_nationkey AND s.rn <= 3
LEFT JOIN 
    HighValueCustomers c ON c.c_custkey = (SELECT o.o_custkey 
                                              FROM RecentOrders o 
                                              WHERE o.o_orderkey = ld.l_orderkey 
                                              LIMIT 1)
LEFT JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    LineitemDetails ld ON l.l_orderkey = ld.l_orderkey
GROUP BY 
    r.r_name, n.n_name, s.s_name, c.c_name
HAVING 
    SUM(ld.revenue) > 10000 OR COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    TotalRevenue DESC NULLS LAST;
