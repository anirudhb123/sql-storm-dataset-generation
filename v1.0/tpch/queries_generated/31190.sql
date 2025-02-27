WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_partkey, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal + ps.ps_supplycost, ps.ps_partkey, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplyChain sc ON ps.ps_partkey = sc.ps_partkey
)
SELECT n.n_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count, 
       SUM(o.o_totalprice) AS total_sales, 
       AVG(l.l_extendedprice) AS avg_price,
       MAX(s.sc_acctbal) AS max_supplier_balance
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
INNER JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN (
    SELECT DISTINCT s_suppkey, SUM(ps_supplycost) AS sc_acctbal
    FROM SupplyChain
    GROUP BY s_suppkey
) s ON s.s_suppkey = c.c_nationkey  
WHERE o.o_orderdate BETWEEN '2023-01-01' AND CURRENT_DATE
GROUP BY n.n_name
HAVING SUM(o.o_totalprice) > 100000
ORDER BY total_sales DESC
LIMIT 10;
