WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
        AND p.p_retailprice > 10.00
        AND l.l_shipdate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY 
        n.n_nationkey, n.n_name
),
TopSales AS (
    SELECT 
        nation_name,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS overall_rank
    FROM 
        RegionalSales
)
SELECT 
    t.nation_name,
    t.total_sales,
    COALESCE(p.p_container, 'UNKNOWN') AS container,
    CASE 
        WHEN t.total_sales IS NULL THEN 'No sales'
        ELSE 'Sales exist'
    END AS sales_condition,
    STRING_AGG(DISTINCT p.p_mfgr, ', ') AS manufacturers
FROM 
    TopSales t
LEFT JOIN 
    partsupp ps ON t.total_sales > ps.ps_supplycost
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    t.overall_rank <= 5
GROUP BY 
    t.nation_name, t.total_sales
ORDER BY 
    t.total_sales DESC NULLS LAST;
