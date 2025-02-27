WITH RegionSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        DENSE_RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        l.l_shipdate BETWEEN '2021-01-01' AND '2021-12-31'
        AND o.o_orderstatus IN ('F', 'O')
    GROUP BY 
        r.r_regionkey, r.r_name
),
CustomerSegmentation AS (
    SELECT 
        c.c_mktsegment,
        AVG(c.c_acctbal) AS avg_account_balance,
        SUM(CASE WHEN c.c_acctbal IS NULL THEN 1 ELSE 0 END) AS null_accounts 
    FROM 
        customer c
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    r.region_name,
    CASE 
        WHEN c.c_mktsegment IS NULL THEN 'Undefined Segment'
        ELSE c.c_mktsegment 
    END AS market_segment,
    rs.total_sales,
    rs.order_count,
    cs.avg_account_balance,
    cs.null_accounts
FROM 
    RegionSales rs
LEFT JOIN 
    CustomerSegmentation cs ON rs.sales_rank = (SELECT MAX(sales_rank) FROM RegionSales)
LEFT JOIN 
    customer c ON c.c_custkey = (
        SELECT c.c_custkey FROM customer 
        WHERE c.c_nationkey = (
            SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 
                (SELECT r.r_regionkey FROM region r WHERE r.r_name = rs.region_name)
        ) LIMIT 1
    )
WHERE 
    rs.total_sales > (SELECT AVG(total_sales) FROM RegionSales)
OR 
    cs.null_accounts > 5
ORDER BY 
    rs.total_sales DESC, c.c_mktsegment IS NULL;
