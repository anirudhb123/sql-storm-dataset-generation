WITH RecursiveSupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, level + 1
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN RecursiveSupplierHierarchy r ON r.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 5000
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
CustomerSpend AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spend
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, 
       COALESCE(SUM(cs.total_spend), 0) AS regional_spend,
       COUNT(DISTINCT cs.c_custkey) AS customer_count,
       COUNT(DISTINCT so.o_orderkey) AS order_count,
       AVG(rh.s_acctbal) AS avg_supplier_balance
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN RecursiveSupplierHierarchy rh ON s.s_suppkey = rh.s_suppkey
LEFT JOIN CustomerSpend cs ON n.n_nationkey = (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_custkey = cs.c_custkey)
LEFT JOIN RankedOrders so ON so.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'F' 
      AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
GROUP BY r.r_name
ORDER BY regional_spend DESC
LIMIT 10;
