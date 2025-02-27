WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        sh.level + 1
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        SalesHierarchy sh ON o.o_orderkey = sh.o_orderkey
    WHERE 
        o.o_orderdate < cast('1998-10-01' as date)
),
RankedSales AS (
    SELECT 
        sh.c_name,
        sh.o_orderdate,
        sh.o_totalprice,
        RANK() OVER (PARTITION BY sh.c_name ORDER BY sh.o_totalprice DESC) AS price_rank
    FROM 
        SalesHierarchy sh
),
AggregateSales AS (
    SELECT 
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS num_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        c.c_name
)
SELECT 
    p.p_name,
    COALESCE(a.total_sales, 0) AS total_sales,
    a.num_orders,
    r.r_name AS region_name,
    CASE 
        WHEN COALESCE(a.total_sales, 0) = 0 THEN 'No Sales'
        WHEN a.total_sales > 50000 THEN 'High Sales'
        ELSE 'Regular Sales'
    END AS sales_category
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    AggregateSales a ON p.p_name = a.c_name
WHERE 
    r.r_name IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 10;