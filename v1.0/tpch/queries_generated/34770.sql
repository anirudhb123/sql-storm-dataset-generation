WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) FROM supplier s2
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN TopSuppliers ts ON s.s_suppkey < ts.s_suppkey
    WHERE ts.rank < 10
),
SalesData AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders,
        RANK() OVER (ORDER BY COALESCE(sd.total_sales, 0) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN SalesData sd ON c.c_custkey = sd.o_custkey 
),
FinalReport AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_sales,
        cs.total_orders,
        ts.s_name AS top_supplier,
        ts.s_acctbal AS supplier_acctbal
    FROM CustomerSales cs
    LEFT JOIN TopSuppliers ts ON cs.sales_rank <= 10
)
SELECT 
    fr.c_custkey,
    fr.c_name,
    fr.total_sales,
    fr.total_orders,
    CASE 
        WHEN fr.top_supplier IS NOT NULL THEN fr.top_supplier
        ELSE 'No Top Supplier'
    END AS top_supplier,
    CASE 
        WHEN fr.supplier_acctbal IS NULL THEN 'N/A'
        ELSE CAST(fr.supplier_acctbal AS VARCHAR)
    END AS supplier_acctbal
FROM FinalReport fr
WHERE fr.total_sales > 1000
ORDER BY fr.total_sales DESC;
