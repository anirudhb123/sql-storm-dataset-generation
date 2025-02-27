WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT o.orderkey, o.custkey, o.orderdate, o.totalprice, h.level + 1
    FROM orders o
    JOIN OrderHierarchy h ON o.o_orderkey = h.o_orderkey
    WHERE o.o_orderdate < h.o_orderdate
),
AvgSupplierCost AS (
    SELECT ps.s_partkey, AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
SuppSales AS (
    SELECT s.s_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON l.l_partkey = ps.ps_partkey
    GROUP BY s.s_suppkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_sales, 
           RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank,
           COALESCE(ac.avg_cost, 0) AS avg_supply_cost
    FROM supplier s
    LEFT JOIN SuppSales ss ON s.s_suppkey = ss.s_suppkey
    LEFT JOIN AvgSupplierCost ac ON s.s_suppkey = ac.s_partkey
)
SELECT oh.o_orderkey, oh.o_totalprice, oh.o_orderdate, rs.s_suppkey, 
       rs.s_name, rs.total_sales, rs.avg_supply_cost
FROM OrderHierarchy oh
JOIN RankedSuppliers rs ON rs.sales_rank <= 10
WHERE oh.o_totalprice > (
    SELECT AVG(oh2.o_totalprice) 
    FROM OrderHierarchy oh2 
    WHERE oh2.level = 1
    AND oh2.o_totalprice IS NOT NULL
)
ORDER BY oh.o_orderdate DESC, rs.total_sales DESC;
