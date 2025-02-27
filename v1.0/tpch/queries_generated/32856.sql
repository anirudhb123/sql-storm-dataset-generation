WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000

    UNION ALL

    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        sh.level + 1
    FROM 
        partsupp ps
    JOIN 
        SupplierHierarchy sh ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 50)
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerRevenue AS (
    SELECT 
        c.c_name,
        r.r_name AS region,
        SUM(ro.total_revenue) AS total_revenue
    FROM 
        customer c
    JOIN 
        RecentOrders ro ON c.c_custkey = ro.o_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        c.c_name, r.r_name
)

SELECT 
    ch.c_name,
    ch.total_revenue,
    sh.s_name AS supplier_name,
    sh.level
FROM 
    CustomerRevenue ch
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'USA%')
WHERE 
    ch.total_revenue > (SELECT AVG(total_revenue) FROM CustomerRevenue) AND 
    sh.level IS NOT NULL
ORDER BY 
    ch.total_revenue DESC
LIMIT 10;
