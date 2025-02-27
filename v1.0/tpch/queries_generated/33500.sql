WITH RECURSIVE SupplyCostCTE AS (
    SELECT ps_partkey, ps_supplycost, ps_availqty, 1 AS level
    FROM partsupp
    WHERE ps_availqty > 0

    UNION ALL

    SELECT ps.partkey, ps.ps_supplycost * 0.9 AS ps_supplycost, ps.ps_availqty, level + 1
    FROM partsupp ps
    JOIN SupplyCostCTE scte ON ps.ps_partkey = scte.ps_partkey
    WHERE level < 10
), 

RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
), 

SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           COALESCE(NULLIF(s.s_comment, ''), 'No Comment') AS s_comment
    FROM supplier s
    WHERE s.s_acctbal > 50000.00
)

SELECT p.p_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
       AVG(s.s_acctbal) AS avg_supplier_balance,
       COUNT(DISTINCT o.o_orderkey) AS order_count
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey 
LEFT JOIN RankedOrders o ON l.l_orderkey = o.o_orderkey 
JOIN SupplierInfo s ON l.l_suppkey = s.s_suppkey 
RIGHT OUTER JOIN SupplyCostCTE sc ON p.p_partkey = sc.ps_partkey 
WHERE sc.ps_supplycost IS NOT NULL 
  AND (l.l_returnflag = 'R' OR l.l_linestatus = 'O')
GROUP BY p.p_name
HAVING revenue > 10000.00
ORDER BY avg_supplier_balance DESC
LIMIT 10;
