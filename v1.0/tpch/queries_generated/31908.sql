WITH RECURSIVE Sales_CTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice - l.l_discount) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice - l.l_discount) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
), SupplierRank AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), RegionSales AS (
    SELECT 
        r.r_name,
        SUM(sct.total_sales) AS regional_sales
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN Sales_CTE sct ON o.o_orderkey = sct.o_orderkey
    GROUP BY r.r_name
    HAVING SUM(sct.total_sales) IS NOT NULL
)

SELECT 
    r.r_name,
    COALESCE(rs.regional_sales, 0) AS total_sales,
    COALESCE(sr.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN rs.regional_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Available'
    END AS sales_status,
    ROW_NUMBER() OVER (ORDER BY COALESCE(rs.regional_sales, 0) DESC) AS region_rank
FROM RegionSales rs
FULL OUTER JOIN SupplierRank sr ON sr.supply_rank <= 10
ORDER BY total_sales DESC, total_supply_cost DESC;
