WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 0 AS level
    FROM customer
    WHERE c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > 1000
),
TotalSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate >= DATE '2022-01-01'
    GROUP BY l.l_orderkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost,
           RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerSales AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
RegionSaleDetails AS (
    SELECT r.r_name, SUM(l.l_extendedprice) AS region_sales,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM region r 
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_name
)
SELECT ch.c_name, ch.level, COALESCE(ts.total_revenue, 0) AS total_revenue,
       COALESCE(cs.total_spent, 0) AS total_spent, rs.supplier_cost,
       rg.r_name, rg.region_sales, rg.order_count
FROM CustomerHierarchy ch
LEFT JOIN TotalSales ts ON ts.l_orderkey = (SELECT o_orderkey FROM orders WHERE o_custkey = ch.c_custkey LIMIT 1)
LEFT JOIN CustomerSales cs ON cs.c_custkey = ch.c_custkey
LEFT JOIN RankedSuppliers rs ON rs.s_suppkey = (SELECT ps_suppkey FROM partsupp ps 
                                                  WHERE ps.ps_partkey IN (SELECT p_partkey FROM part WHERE p_size > 10 LIMIT 1) LIMIT 1)
LEFT JOIN RegionSaleDetails rg ON rg.r_name = (SELECT r_name FROM region WHERE r_regionkey = ch.c_nationkey LIMIT 1)
WHERE ch.level < 3
ORDER BY ch.level, coalesce(total_revenue, 0) DESC, coalesce(total_spent, 0) DESC;
