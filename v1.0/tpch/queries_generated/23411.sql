WITH RecursivePart AS (
    SELECT p_partkey, p_name, p_retailprice
    FROM part
    WHERE p_size BETWEEN 5 AND 10
    UNION ALL
    SELECT p.partkey, p.p_name, p.p_retailprice * 1.1
    FROM part p
    JOIN RecursivePart rp ON p.p_partkey = rp.p_partkey + 1
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier WHERE s_comment IS NOT NULL
    )
),
SalesSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, ss.total_sales,
           RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM customer c
    JOIN SalesSummary ss ON c.c_custkey = ss.o_custkey
)
SELECT rp.p_name, rp.p_retailprice, f.s_name, rc.total_sales
FROM RecursivePart rp
LEFT JOIN FilteredSuppliers f ON f.s_acctbal > (
    SELECT AVG(s_acctbal) FROM FilteredSuppliers
)
JOIN RankedCustomers rc ON rc.sales_rank <= 10 AND (rc.total_sales > 1000 OR rc.total_sales IS NULL)
WHERE rp.p_retailprice < (
    SELECT MAX(p_retailprice) FROM part WHERE p_container = 'BOX'
)
ORDER BY rp.p_retailprice DESC, rc.total_sales ASC
LIMIT 50;
