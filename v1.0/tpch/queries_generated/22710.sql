WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '2021-01-01'
        AND o.o_orderstatus IN ('O', 'F')
),
SupplierSales AS (
    SELECT
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey
),
DistinctCustomers AS (
    SELECT
        c.c_nationkey,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM
        customer c
    GROUP BY c.c_nationkey
)

SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    (SELECT COUNT(*) FROM RankedOrders ro WHERE ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)) AS order_count,
    CASE
        WHEN ss.order_count > 100 THEN 'High'
        WHEN ss.order_count BETWEEN 51 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    r.r_name,
    n.n_name,
    dc.unique_customers
FROM
    part p
LEFT JOIN SupplierSales ss ON p.p_partkey = ss.s_suppkey
JOIN nation n ON n.n_nationkey = ss.s_suppkey
JOIN region r ON r.r_regionkey = n.n_regionkey
JOIN DistinctCustomers dc ON dc.c_nationkey = n.n_nationkey
WHERE
    (p.p_container LIKE '%BOX%' OR p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2))
    AND (p.p_size IS NOT NULL OR EXISTS (SELECT 1 FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_discount > 0))
ORDER BY
    total_sales DESC,
    r.r_name ASC
FETCH FIRST 10 ROWS ONLY;
