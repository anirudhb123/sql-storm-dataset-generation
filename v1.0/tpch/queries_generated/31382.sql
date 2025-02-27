WITH RECURSIVE RegionSales (r_name, total_sales, lvl) AS (
    SELECT r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 1
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY r.r_name
    UNION ALL
    SELECT r_name, total_sales * 1.1, lvl + 1
    FROM RegionSales
    WHERE lvl < 3
),
RankedSales AS (
    SELECT r_name, total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM RegionSales
),
SupplierSales AS (
    SELECT s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY s.s_name
),
CombinedSales AS (
    SELECT r.r_name, COALESCE(s.supplier_sales, 0) AS supplier_sales
    FROM region r
    LEFT JOIN SupplierSales s ON r.r_name = s.s_name
),
FinalReport AS (
    SELECT cr.r_name, 
           cr.total_sales,
           cs.supplier_sales,
           (cr.total_sales - cs.supplier_sales) AS net_income
    FROM RankedSales cr
    LEFT JOIN CombinedSales cs ON cr.r_name = cs.r_name
)
SELECT 
    fr.r_name,
    fr.total_sales,
    fr.supplier_sales,
    fr.net_income,
    CASE 
        WHEN fr.net_income IS NULL THEN 'No Profit'
        WHEN fr.net_income < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM FinalReport fr
WHERE fr.total_sales > 1000000
ORDER BY fr.net_income DESC
LIMIT 10;
