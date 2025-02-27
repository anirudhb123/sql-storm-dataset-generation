WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
),
RankedSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(sc.total_sales, 0) AS total_sales
    FROM customer c
    LEFT JOIN SalesCTE sc ON c.c_custkey = sc.c_custkey
    WHERE COALESCE(sc.total_sales, 0) > 0
),
SupplyCostCTE AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size >= 10
    GROUP BY ps.ps_partkey
)
SELECT 
    r.n_name AS nation_name,
    COUNT(DISTINCT rs.c_custkey) AS customer_count,
    SUM(rs.total_sales) AS total_sales,
    COALESCE(SUM(s.total_supply_cost), 0) AS total_supply_cost,
    AVG(rs.total_sales) AS avg_sales_per_customer
FROM nation r
LEFT JOIN supplier s ON r.n_nationkey = s.s_nationkey
LEFT JOIN RankedSales rs ON r.n_nationkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
LEFT JOIN SupplyCostCTE sc ON s.s_suppkey = sc.ps_partkey
GROUP BY r.n_name
HAVING SUM(rs.total_sales) > 10000
ORDER BY total_sales DESC
LIMIT 10;
