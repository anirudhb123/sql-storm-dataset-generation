
WITH RegionalSales AS (
    SELECT
        r_name AS region_name,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM
        lineitem
    JOIN orders ON l_orderkey = o_orderkey
    JOIN customer ON o_custkey = c_custkey
    JOIN supplier ON l_suppkey = s_suppkey
    JOIN nation ON s_nationkey = n_nationkey
    JOIN region ON n_regionkey = r_regionkey
    WHERE
        o_orderdate >= DATE '1996-01-01' AND o_orderdate < DATE '1997-01-01'
    GROUP BY
        r_name
),
TopRegions AS (
    SELECT
        region_name,
        total_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        RegionalSales
)
SELECT
    TR.region_name,
    TR.total_sales,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(s.s_acctbal) AS average_supplier_balance
FROM
    TopRegions TR
JOIN supplier s ON EXISTS (
    SELECT 1
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_suppkey = s.s_suppkey AND p.p_container = 'MED BOX'
)
JOIN customer c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE
    TR.sales_rank <= 5
GROUP BY
    TR.region_name, TR.total_sales
ORDER BY
    TR.total_sales DESC;
