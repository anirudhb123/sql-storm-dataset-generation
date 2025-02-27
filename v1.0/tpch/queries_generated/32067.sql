WITH RECURSIVE RegionalSales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_regionkey, r.r_name
    UNION ALL
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(d.total_sales)
    FROM 
        RegionalSales d
    JOIN 
        region r ON d.r_regionkey = r.r_regionkey
    WHERE 
        d.total_sales > 10000
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS customer_total,
    RANK() OVER (PARTITION BY c.c_custkey ORDER BY COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) DESC) AS sales_rank
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    RegionalSales r ON c.c_nationkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' 
    AND (c.c_acctbal IS NULL OR c.c_acctbal > 0) 
GROUP BY 
    c.c_custkey, c.c_name
HAVING 
    customer_total > 1000
ORDER BY 
    customer_total DESC;
