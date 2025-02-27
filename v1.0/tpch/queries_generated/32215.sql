WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 3
),
SalesData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY c.c_custkey, c.c_name
),
PartSaleInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS sales_count
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedParts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM PartSaleInfo p
),
RegionsWithComments AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COALESCE(r.r_comment, 'No comments') AS r_comment
    FROM region r
)
SELECT 
    r.r_name,
    s.s_name,
    sf.total_sales AS top_sales_customer,
    rp.p_name,
    rp.total_revenue
FROM RegionsWithComments r
LEFT JOIN SupplierHierarchy s ON s.s_acctbal > 10000
LEFT JOIN SalesData sf ON sf.c_custkey = (
    SELECT c.c_custkey
    FROM SalesData c
    WHERE c.total_sales = (SELECT MAX(total_sales) FROM SalesData)
    LIMIT 1
)
LEFT JOIN RankedParts rp ON rp.revenue_rank <= 10
ORDER BY r.r_name, s.s_name, rp.total_revenue DESC
