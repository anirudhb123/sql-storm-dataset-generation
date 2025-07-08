
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    WHERE 
        o.o_orderdate >= DATE '1994-01-01' 
        AND o.o_orderdate < DATE '1995-01-01'
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    r.region, 
    r.total_sales, 
    COUNT(s.s_suppkey) AS supplier_count, 
    AVG(s.s_acctbal) AS average_supplier_balance
FROM 
    TopRegions r
JOIN 
    partsupp ps ON ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE n.n_name = r.region)
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    r.sales_rank <= 5
GROUP BY 
    r.region, r.total_sales
ORDER BY 
    r.total_sales DESC;
