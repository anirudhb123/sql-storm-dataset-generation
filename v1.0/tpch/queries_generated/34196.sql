WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_size > 10
),
AggregatedSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate < CURRENT_DATE
    GROUP BY o.o_orderkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(a.total_sales) AS total_spent
    FROM customer c
    LEFT JOIN AggregatedSales a ON c.c_custkey = a.o_orderkey
    GROUP BY c.c_custkey, c.c_name
    HAVING total_spent IS NOT NULL AND total_spent > 5000
)
SELECT 
    th.s_name AS supplier_name,
    tp.p_name AS part_name,
    tp.p_retailprice AS price,
    tc.c_name AS customer_name,
    tc.total_spent AS customer_total_spent,
    COALESCE(r.r_name, 'Unknown Region') AS region
FROM SupplierHierarchy th
LEFT JOIN partsupp ps ON th.s_suppkey = ps.ps_suppkey
LEFT JOIN TopParts tp ON ps.ps_partkey = tp.p_partkey AND tp.rank <= 5
LEFT JOIN nation n ON th.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN TopCustomers tc ON tc.total_spent > 0
ORDER BY supplier_name, price DESC
LIMIT 50;
