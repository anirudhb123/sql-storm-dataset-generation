
WITH RECURSIVE RegionSales AS (
    SELECT
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY r.r_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
    UNION ALL
    SELECT
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-10-01'
    GROUP BY r.r_name
),
TopRegions AS (
    SELECT
        region,
        total_sales,
        sales_rank
    FROM
        RegionSales
    WHERE sales_rank <= 5
)
SELECT
    tar.region,
    tar.total_sales,
    COALESCE(c.c_acctbal, 0) AS customer_balance,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS avg_order_value
FROM
    TopRegions tar
LEFT JOIN customer c ON c.c_nationkey = (
    SELECT n.n_nationkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name = tar.region
    LIMIT 1
)
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
GROUP BY tar.region, tar.total_sales, c.c_acctbal
ORDER BY tar.total_sales DESC, customer_balance DESC;
