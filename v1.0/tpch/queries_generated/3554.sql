WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
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
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= date '2023-01-01' 
        AND o.o_orderdate < date '2023-12-31'
    GROUP BY 
        r.r_name
),
CustomerStats AS (
    SELECT 
        c.c_nationkey,
        AVG(c.c_acctbal) AS avg_account_balance,
        COUNT(c.c_custkey) AS customer_count
    FROM 
        customer c
    GROUP BY 
        c.c_nationkey
),
SalesRanked AS (
    SELECT 
        rs.region_name,
        rs.total_sales,
        cs.avg_account_balance,
        RANK() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM 
        RegionalSales rs
    JOIN 
        CustomerStats cs ON cs.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE r.r_regionkey = n.n_regionkey)
    WHERE 
        cs.customer_count > 10
)
SELECT 
    sr.region_name,
    sr.total_sales,
    sr.avg_account_balance,
    sr.sales_rank,
    CASE 
        WHEN sr.total_sales > 100000 THEN 'High Sales'
        ELSE 'Low Sales' 
    END AS sales_category
FROM 
    SalesRanked sr
ORDER BY 
    sr.sales_rank;
