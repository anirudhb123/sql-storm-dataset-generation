WITH RECURSIVE SalesCTE AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
    UNION ALL
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN SalesCTE s ON c.c_custkey = s.c_custkey 
    WHERE o.o_orderdate < DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
),
RankedSales AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_sales,
        RANK() OVER (ORDER BY COALESCE(SUM(o.o_totalprice), 0) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31' OR o.o_orderdate IS NULL
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartData AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_value
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_size
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
)
SELECT
    rs.c_custkey,
    rs.c_name,
    rs.total_sales,
    s.p_name,
    COALESCE(sp.supply_value, 0) AS supply_value,
    CASE
        WHEN rs.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM RankedSales rs
LEFT JOIN FilteredParts s ON s.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
LEFT JOIN SupplierPartData sp ON sp.ps_partkey = s.p_partkey
WHERE rs.total_sales > 5000
ORDER BY rs.total_sales DESC, rs.c_name;
