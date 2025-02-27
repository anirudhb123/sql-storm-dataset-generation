WITH RECURSIVE CTE_Supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    FROM supplier s
    JOIN CTE_Supplier cte ON s.s_nationkey = cte.s_nationkey
    WHERE s.s_acctbal > cte.s_acctbal
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_partkey) AS product_count,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank 
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
SupplierRegion AS (
    SELECT n.n_name AS nation, r.r_name AS region, SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
)
SELECT sr.nation, sr.region, ROUND(sr.total_acctbal, 2) AS total_balance,
       (SELECT COUNT(*) FROM CTE_Supplier) AS supplier_count,
       (SELECT AVG(total_sales) FROM OrderStats WHERE sales_rank <= 10) AS avg_top_orders
FROM SupplierRegion sr
LEFT JOIN CTE_Supplier cs ON sr.nation = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = cs.s_nationkey)
WHERE sr.total_acctbal IS NOT NULL
ORDER BY sr.region, sr.nation;
