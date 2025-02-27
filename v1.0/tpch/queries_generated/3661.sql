WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSales AS (
    SELECT 
        ts.p_partkey,
        ts.p_name,
        ts.total_sales,
        r.r_name AS region_name
    FROM 
        RankedSales ts
    JOIN 
        partsupp ps ON ts.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ts.sales_rank = 1
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT 
        ts.region_name,
        COUNT(DISTINCT co.c_custkey) AS unique_customers,
        SUM(co.total_spent) AS total_revenue,
        COUNT(ts.p_partkey) AS total_products
    FROM 
        TopSales ts
    LEFT JOIN 
        CustomerOrders co ON ts.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE n.n_comment IS NOT NULL))
    GROUP BY 
        ts.region_name
)
SELECT 
    region_name,
    unique_customers,
    total_revenue,
    total_products
FROM 
    FinalReport
WHERE 
    total_revenue IS NOT NULL AND total_products > 0
ORDER BY 
    total_revenue DESC, unique_customers DESC;
