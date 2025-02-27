WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        1 AS level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
    UNION ALL
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(sub.total_sales) AS total_sales,
        level + 1
    FROM SalesCTE sub
    JOIN customer c ON c.c_custkey = sub.c_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(sub.total_sales) > 5000 
),
RankedSales AS (
    SELECT 
        s.c_custkey,
        s.c_name,
        s.total_sales,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM SalesCTE s
),
SupplierStats AS (
    SELECT 
        n.n_name AS nation,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
)
SELECT 
    r.r_name,
    COALESCE(ss.supplier_count, 0) AS unique_suppliers,
    COALESCE(ss.avg_acctbal, 0) AS avg_supplier_acctbal,
    COALESCE(rs.sales_rank, 'No Sales') AS customer_sales_rank
FROM region r
LEFT JOIN SupplierStats ss ON r.r_name = ss.nation
LEFT JOIN RankedSales rs ON r.r_name = (SELECT n.n_name FROM nation n 
    WHERE n.n_nationkey = (SELECT DISTINCT c.c_nationkey 
                           FROM customer c 
                           WHERE c.c_custkey IN (SELECT c_custkey 
                                                 FROM RankedSales)))
WHERE r.r_regionkey IS NOT NULL
ORDER BY r.r_regionkey, unique_suppliers DESC, customer_sales_rank;
