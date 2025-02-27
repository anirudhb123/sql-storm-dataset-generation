WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
SalesData AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(sd.total_sales) AS total_customer_sales
    FROM customer c
    JOIN SalesData sd ON sd.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_custkey = c.c_custkey
    )
    GROUP BY c.c_custkey, c.c_name
)
SELECT DISTINCT
    CASE 
        WHEN cs.total_customer_sales IS NULL THEN 'No Sales'
        ELSE CONCAT(cs.c_name, ' has total sales of ', cs.total_customer_sales)
    END AS sales_summary,
    CASE 
        WHEN COUNT(DISTINCT ps.ps_partkey) > 0 THEN 'Part Supplied'
        ELSE 'No Parts'
    END AS part_status
FROM RankedSuppliers rs
LEFT JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
LEFT JOIN CustomerSales cs ON rs.s_suppkey = cs.c_custkey
WHERE rs.rank = 1 AND (rs.s_acctbal IS NOT NULL OR ps.ps_supplycost IS NULL)
GROUP BY cs.total_customer_sales, cs.c_name
HAVING SUM(COALESCE(rs.s_acctbal, 0)) <> 0 OR cs.total_customer_sales IS NOT NULL
ORDER BY sales_summary DESC;
