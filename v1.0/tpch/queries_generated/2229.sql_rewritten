WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
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
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
        AND l.l_linestatus = 'O'
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
)
SELECT 
    tr.nation_name,
    tr.total_sales,
    tr.sales_rank,
    COALESCE(s.s_acctbal, 0) AS supplier_account_balance
FROM 
    TopRegions tr
LEFT JOIN 
    supplier s ON tr.nation_name = (
        SELECT n_name 
        FROM nation 
        WHERE n_nationkey = s.s_nationkey
    )
WHERE 
    tr.sales_rank <= 5
ORDER BY 
    tr.total_sales DESC;