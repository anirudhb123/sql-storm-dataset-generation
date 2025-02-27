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
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        r.r_name
), 
TopSales AS (
    SELECT 
        region,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    t.region, 
    t.total_sales,
    COUNT(DISTINCT n.n_nationkey) AS nations_count,
    SUM(p.p_retailprice * ps.ps_availqty) AS total_inventory_value
FROM 
    TopSales t
JOIN 
    nation n ON t.region = (SELECT r.r_name FROM region r WHERE r.r_regionkey = n.n_regionkey)
JOIN 
    partsupp ps ON ps.ps_supplycost > 1000
JOIN 
    part p ON p.p_partkey = ps.ps_partkey
WHERE 
    t.sales_rank <= 5
GROUP BY 
    t.region, t.total_sales
ORDER BY 
    t.total_sales DESC;
