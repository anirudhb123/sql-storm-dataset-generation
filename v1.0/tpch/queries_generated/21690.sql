WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY 
        c.c_custkey
),
SupplierRegions AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS supplier_nation,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey 
    WHERE 
        s.s_comment IS NOT NULL
),
MaxOrderValue AS (
    SELECT 
        MAX(total_spent) as max_spent
    FROM 
        CustomerOrders
),
JoinExample AS (
    SELECT 
        c.c_name,
        p.p_name,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice) DESC) AS rank_order
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    INNER JOIN 
        RankedSales rs ON l.l_partkey = rs.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal = (SELECT MAX(s2.s_acctbal) FROM supplier s2 WHERE s2.s_comment IS NOT NULL)
    GROUP BY 
        c.c_name, p.p_name, s.s_name
)
SELECT 
    c.c_name,
    r.region_name,
    SUM(p.p_retailprice) AS total_retail_price,
    COUNT(o.o_orderkey) AS order_count,
    CASE 
        WHEN SUM(l.l_extendedprice) IS NULL THEN 'No sales'
        ELSE 'Sales exist'
    END AS sales_existence
FROM 
    customer c
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    part p ON p.p_partkey = l.l_partkey
LEFT JOIN 
    SupplierRegions sr ON c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = sr.supplier_nation)
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = c.c_nationkey)
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    c.c_name, r.region_name
HAVING 
    SUM(p.p_retailprice) > (SELECT * FROM MaxOrderValue)
ORDER BY 
    total_retail_price DESC;
