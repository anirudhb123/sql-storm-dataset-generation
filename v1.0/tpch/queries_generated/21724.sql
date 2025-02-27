WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
        AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        n.n_name, n.n_regionkey
), 
TopNations AS (
    SELECT 
        nation_name 
    FROM 
        RegionalSales 
    WHERE 
        sales_rank <= 3
),
DiscountedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty * p.p_retailprice * (1 - CASE WHEN l.l_discount IS NULL THEN 0 ELSE l.l_discount END)) AS discounted_total 
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    p.p_name, 
    COALESCE(ds.discounted_total, 0) AS total_discounted_sales, 
    rs.total_sales, 
    CASE 
        WHEN rs.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM 
    DiscountedParts ds
FULL OUTER JOIN 
    RegionalSales rs ON ds.p_name LIKE '%' || rs.nation_name || '%'
WHERE 
    ds.discounted_total > 1000 OR rs.total_sales IS NULL
ORDER BY 
    total_discounted_sales DESC NULLS LAST, 
    sales_status;
