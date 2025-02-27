
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) as rank
    FROM part p
)
SELECT r.r_name, 
       SUM(CASE WHEN li.l_returnflag = 'N' THEN li.l_extendedprice * (1 - li.l_discount) END) AS total_sales,
       COUNT(DISTINCT o.o_custkey) AS unique_customers,
       AVG(s.s_acctbal) AS avg_acct_balance,
       STRING_AGG(DISTINCT CONCAT(c.c_name, ' from ', s.s_name)) AS customers_suppliers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN RankedParts p ON ps.ps_partkey = p.p_partkey AND p.rank <= 5
LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE s.s_acctbal IS NOT NULL
  AND o.o_orderstatus IN ('F', 'O')
  AND li.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY r.r_name, s.s_acctbal
ORDER BY total_sales DESC, avg_acct_balance DESC;
