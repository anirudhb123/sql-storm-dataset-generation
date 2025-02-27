WITH RECURSIVE SalesCTE AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
    UNION ALL
    SELECT s.o_orderkey, s.o_orderdate, s.total_sales
    FROM SalesCTE s
    JOIN orders o ON s.o_orderkey = o.o_orderkey
    WHERE s.total_sales < (SELECT AVG(total_sales) FROM SalesCTE)
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING total_supply_cost > 10000
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_brand
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
    AND p.p_retailprice IS NOT NULL
),
OrderStatusCount AS (
    SELECT o.o_orderstatus, COUNT(*) AS order_count
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderstatus
)
SELECT
    ns.n_name,
    COALESCE(RS.total_supply_cost, 0) AS total_cost,
    SUM(CASE WHEN l.l_shipdate <= CURRENT_DATE THEN l.l_extendedprice ELSE 0 END) AS total_revenue,
    ROUND(AVG(sp.total_sales), 2) AS avg_sales
FROM nation ns
LEFT JOIN RankedSuppliers RS ON ns.n_nationkey = RS.s_suppkey
LEFT JOIN lineitem l ON RS.s_suppkey = l.l_suppkey
LEFT JOIN SalesCTE sp ON l.l_orderkey = sp.o_orderkey
WHERE ns.n_nationkey IS NOT NULL
GROUP BY ns.n_name, RS.total_supply_cost
HAVING SUM(CASE WHEN l.l_discount IS NULL THEN 0 ELSE l.l_discount END) > 0
ORDER BY total_cost DESC, avg_sales DESC
LIMIT 100;
