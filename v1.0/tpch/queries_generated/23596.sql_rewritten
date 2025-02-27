WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
    WHERE
        l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY
        n.n_nationkey, n.n_name
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),

TopNations AS (
    SELECT 
        nation_name,
        total_sales
    FROM 
        RegionalSales
    WHERE
        sales_rank <= 3
),

CustomersWithSales AS (
    SELECT 
        c.c_name AS customer_name,
        c.c_acctbal AS account_balance,
        COALESCE(ts.total_sales, 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        TopNations ts ON ts.nation_name = (
            SELECT 
                n.n_name
            FROM 
                nation n
            WHERE 
                n.n_nationkey = c.c_nationkey
        )
    WHERE 
        c.c_acctbal IS NOT NULL
),

AggregateSales AS (
    SELECT 
        SUM(total_sales) AS overall_sales,
        AVG(account_balance) AS average_balance
    FROM 
        CustomersWithSales
)

SELECT 
    asv.overall_sales,
    asv.average_balance,
    CASE 
        WHEN asv.average_balance IS NULL THEN 'No Balance'
        WHEN asv.average_balance > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value,
    CASE 
        WHEN asv.overall_sales < 50000 THEN 'Underperforming'
        WHEN asv.overall_sales BETWEEN 50000 AND 100000 THEN 'Performing'
        ELSE 'Outstanding'
    END AS sales_performance
FROM 
    AggregateSales asv;