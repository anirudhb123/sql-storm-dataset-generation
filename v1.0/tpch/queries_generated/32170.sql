WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s3.s_acctbal) FROM supplier s3 WHERE s3.s_nationkey = s.s_nationkey)
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_price, 
           COUNT(li.l_orderkey) AS total_items, RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND li.l_shipdate < o.o_orderdate + INTERVAL '30 day'
    GROUP BY o.o_orderkey, o.o_custkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, os.total_price, os.total_items
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    WHERE os.rank <= 5
)
SELECT rh.r_name, COUNT(DISTINCT sh.s_suppkey) AS number_of_suppliers,
       COALESCE(SUM(tc.total_price), 0) AS total_customer_spending
FROM region rh
LEFT JOIN nation n ON n.n_regionkey = rh.r_regionkey
LEFT JOIN supplier sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN TopCustomers tc ON tc.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
GROUP BY rh.r_name
ORDER BY total_customer_spending DESC;
