
WITH RECURSIVE HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    JOIN HighValueSuppliers hvs ON s.s_suppkey = hvs.s_suppkey
    WHERE s.s_acctbal > hvs.s_acctbal * 1.1
), 
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           RANK() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS monthly_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
), 
SupplierAvailability AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)

SELECT p.p_name, n.n_name, 
       SUM(CASE 
            WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE NULL 
           END) AS discounted_price,
       RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice) DESC) AS price_rank,
       COALESCE(SUM(sa.total_available), 0) AS available_quantity,
       CASE 
           WHEN SUM(l.l_extendedprice) IS NULL THEN 'No Sales'
           ELSE 'Sales Present'
       END AS sales_status
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplierAvailability sa ON p.p_partkey = sa.ps_partkey
WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
  AND n.n_name IS NOT NULL
  AND s.s_suppkey IN (SELECT s.s_suppkey FROM HighValueSuppliers)
GROUP BY p.p_name, n.n_name, p.p_partkey
HAVING SUM(l.l_extendedprice) > 10000
ORDER BY sales_status, price_rank;
