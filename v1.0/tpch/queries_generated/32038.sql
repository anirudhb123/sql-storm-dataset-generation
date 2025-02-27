WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           n.n_name AS nation, 
           CASE 
               WHEN s.s_acctbal IS NULL THEN 0 
               ELSE s.s_acctbal 
           END AS adjusted_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           n.n_name AS nation, 
           CASE 
               WHEN s.s_acctbal IS NULL THEN 0 
               ELSE s.s_acctbal 
           END AS adjusted_acctbal
    FROM supplier s
    JOIN SupplyChain sc ON s.s_suppkey = sc.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE sc.adjusted_acctbal > 1000
)
, RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    AND o.o_orderdate >= DATE '2023-01-01'
)
SELECT DISTINCT p.p_name, 
                SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
                MAX(so.adjusted_acctbal) AS max_supplier_balance
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN RankedOrders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN SupplyChain so ON l.l_suppkey = so.s_suppkey
WHERE so.nation IS NOT NULL
AND p.p_retailprice BETWEEN 10.00 AND 500.00
GROUP BY p.p_name
HAVING total_revenue > (SELECT AVG(total_revenue) FROM (
                             SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
                             FROM lineitem
                             GROUP BY l_partkey
                         ) AS avg_revenue)
ORDER BY total_revenue DESC
LIMIT 10;
