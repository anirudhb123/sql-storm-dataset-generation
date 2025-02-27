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
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-12-31'
    GROUP BY 
        r.r_name
),
SalesRanking AS (
    SELECT 
        region,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    s.region, 
    s.total_sales, 
    s.sales_rank,
    COUNT(DISTINCT p.p_partkey) AS part_count,
    AVG(p.p_retailprice) AS avg_price
FROM 
    SalesRanking s
JOIN 
    partsupp ps ON s.region = (SELECT r.r_name
                                FROM region r
                                JOIN nation n ON r.r_regionkey = n.n_regionkey
                                JOIN customer c ON n.n_nationkey = c.c_nationkey
                                JOIN orders o ON c.c_custkey = o.o_custkey
                                JOIN lineitem l ON o.o_orderkey = l.l_orderkey
                                WHERE l.l_partkey = ps.ps_partkey
                                LIMIT 1)
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    s.region, s.total_sales, s.sales_rank
HAVING 
    s.total_sales > 1000000.00
ORDER BY 
    s.sales_rank;