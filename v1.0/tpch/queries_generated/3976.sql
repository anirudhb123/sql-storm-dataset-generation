WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_nationkey
),
TopSales AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        COUNT(DISTINCT ro.o_orderkey) AS order_count,
        SUM(ro.total_sales) AS total_sales_amount
    FROM 
        RankedOrders ro
    LEFT JOIN 
        nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.sales_rank <= 5
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    r.region,
    n.nation,
    COALESCE(ts.order_count, 0) AS order_count,
    COALESCE(ts.total_sales_amount, 0.00) AS total_sales_amount
FROM 
    region r
CROSS JOIN 
    nation n
LEFT JOIN 
    TopSales ts ON r.r_name = ts.region AND n.n_name = ts.nation
WHERE 
    r.r_name IS NOT NULL OR n.n_name IS NOT NULL
ORDER BY 
    r.region, n.nation;
