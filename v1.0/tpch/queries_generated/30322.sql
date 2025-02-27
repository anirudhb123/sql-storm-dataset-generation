WITH RECURSIVE SalesRank AS (
    SELECT 
        s.n_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        s.n_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS region_sales
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
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
SalesComparison AS (
    SELECT 
        sr.n_nationkey,
        sr.total_sales,
        t.region_sales,
        CASE 
            WHEN sr.total_sales > t.region_sales THEN 'Nation surpasses region'
            ELSE 'Region surpasses nation'
        END AS comparison
    FROM 
        SalesRank sr
    JOIN 
        TopRegions t ON sr.n_nationkey = t.r_regionkey
)
SELECT 
    DISTINCT sr.n_nationkey,
    COALESCE(c.total_spent, 0) AS high_value_customer_spending,
    sc.total_sales,
    sc.region_sales,
    sc.comparison
FROM 
    SalesRank sr
LEFT JOIN 
    HighValueCustomers c ON sr.n_nationkey = c.c_custkey
JOIN 
    SalesComparison sc ON sr.n_nationkey = sc.n_nationkey
WHERE 
    sr.sales_rank <= 3
ORDER BY 
    sr.n_nationkey;
