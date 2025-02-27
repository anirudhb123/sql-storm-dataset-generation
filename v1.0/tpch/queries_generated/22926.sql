WITH RankedSuppliers AS (
    SELECT s_suppkey, 
           s_name, 
           s_acctbal, 
           RANK() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) as acctbal_rank
    FROM supplier
),
CustomerStats AS (
    SELECT c_nationkey,
           COUNT(DISTINCT c_custkey) AS num_customers,
           SUM(c_acctbal) AS total_acctbal
    FROM customer
    GROUP BY c_nationkey
),
PartDetails AS (
    SELECT p_partkey, 
           p_name, 
           p_retailprice, 
           CASE 
               WHEN p_size IS NULL THEN 'UNKNOWN' 
               ELSE CAST(p_size AS VARCHAR)
           END AS size_detail
    FROM part
),
OrderSummary AS (
    SELECT o_orderkey, 
           o_orderstatus, 
           SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM orders 
    JOIN lineitem ON o_orderkey = l_orderkey
    GROUP BY o_orderkey, o_orderstatus
)
SELECT r_name, 
       COALESCE(c.num_customers, 0) AS total_customers,
       COALESCE(c.total_acctbal, 0) AS total_acctbal,
       COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
       AVG(R.s_acctbal) AS avg_supplier_acctbal,
       P.size_detail,
       SUM(CASE WHEN O.o_orderstatus = 'F' THEN O.total_sales ELSE 0 END) AS confirmed_sales
FROM region R
LEFT JOIN nation N ON R.r_regionkey = N.n_regionkey
LEFT JOIN CustomerStats C ON N.n_nationkey = C.c_nationkey
LEFT JOIN partsupp PS ON PS.ps_suppkey IN (
    SELECT s_suppkey 
    FROM RankedSuppliers 
    WHERE acctbal_rank <= 3
)
LEFT JOIN PartDetails P ON PS.ps_partkey = P.p_partkey
LEFT JOIN OrderSummary O ON O.o_orderkey != 0
GROUP BY R.r_name, P.size_detail
HAVING COUNT(R.suppkey) > 1 
   AND AVG(R.s_acctbal) IS NOT NULL 
   AND SUM(CASE WHEN O.o_orderstatus = 'F' THEN O.total_sales ELSE 0 END) > 1000
ORDER BY R.r_name, total_customers DESC NULLS LAST;
