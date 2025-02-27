WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
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
        o.o_orderdate >= '1996-01-01'
        AND o.o_orderdate < '1997-01-01'
        AND o.o_orderstatus = 'F'
    GROUP BY 
        n.n_name
),
TopRegions AS (
    SELECT 
        nation_name,
        total_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
AvgCustomerBalance AS (
    SELECT 
        c.c_nationkey,
        AVG(c.c_acctbal) AS avg_balance
    FROM 
        customer c
    GROUP BY 
        c.c_nationkey
)
SELECT 
    tr.nation_name,
    tr.total_sales,
    acb.avg_balance,
    CASE 
        WHEN acb.avg_balance IS NULL THEN 'No Data'
        WHEN tr.total_sales > acb.avg_balance THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_vs_balance,
    CASE 
        WHEN tr.sales_rank <= 5 THEN 'Top 5 Region'
        WHEN tr.sales_rank <= 10 THEN 'Top 10 Region'
        ELSE 'Other Region'
    END AS region_category
FROM 
    TopRegions tr
LEFT JOIN 
    AvgCustomerBalance acb ON tr.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = acb.c_nationkey)
ORDER BY 
    tr.total_sales DESC, 
    tr.nation_name;